defmodule Screens.V2.ScreenData do
  @moduledoc false

  alias Screens.ScreensByAlert
  alias Screens.V2.AlertsWidget
  alias Screens.V2.Template
  alias Screens.V2.WidgetInstance
  alias ScreensConfig.Screen
  alias __MODULE__.{ParallelRunSupervisor, Layout}

  import Screens.Inject
  import Screens.V2.Template.Guards, only: [is_slot_id: 1, is_paged_slot_id: 1]

  @config_cache injected(Screens.Config.Cache)
  @parameters injected(Screens.V2.ScreenData.Parameters)

  @type t :: %{type: atom()}
  @type simulation_data :: %{full_page: t(), flex_zone: [t()]}
  @type variants(data) :: {data, %{String.t() => data}}
  @type screen_id :: String.t()
  @type options :: [
          generator_variant: String.t(),
          pending_config: Screen.t(),
          run_all_variants?: boolean(),
          update_visible_alerts?: boolean()
        ]

  @spec get(screen_id()) :: t()
  @spec get(screen_id(), options()) :: t()
  def get(screen_id, opts \\ []) do
    select_variant(screen_id, opts, &layout_to_data/2)
  end

  @spec simulation(screen_id()) :: simulation_data()
  @spec simulation(screen_id(), options()) :: simulation_data()
  def simulation(screen_id, opts \\ []) do
    select_variant(screen_id, opts, &layout_to_simulation_data/2)
  end

  @spec variants(screen_id()) :: variants(t())
  @spec variants(screen_id(), options()) :: variants(t())
  def variants(screen_id, opts \\ []) do
    all_variants(screen_id, opts, &layout_to_data/2)
  end

  @spec simulation_variants(screen_id()) :: variants(simulation_data())
  @spec simulation_variants(screen_id(), options()) :: variants(simulation_data())
  def simulation_variants(screen_id, opts \\ []) do
    all_variants(screen_id, opts, &layout_to_simulation_data/2)
  end

  @spec select_variant(screen_id(), options(), (Layout.t(), Screen.t() -> data)) :: data
        when data: t() | simulation_data()
  defp select_variant(screen_id, opts, then_fn) do
    config = get_config(screen_id, opts)
    selected_variant = Keyword.get(opts, :generator_variant)

    if Keyword.get(opts, :run_all_variants?, false) do
      other_variants = List.delete([nil | @parameters.variants(config)], selected_variant)

      Enum.each(other_variants, fn variant ->
        {:ok, _pid} =
          Task.Supervisor.start_child(ParallelRunSupervisor, fn ->
            config |> Layout.generate(variant) |> then_fn.(config)
          end)
      end)
    end

    config
    |> Layout.generate(selected_variant, Keyword.get(opts, :query_params))
    |> tap(&update_visible_alerts(&1, screen_id, config, opts))
    |> then_fn.(config)
  end

  @spec all_variants(screen_id(), options(), (Layout.t(), Screen.t() -> data)) ::
          {data, %{atom() => data}}
        when data: t() | simulation_data()
  defp all_variants(screen_id, opts, then_fn) do
    config = get_config(screen_id, opts)

    ParallelRunSupervisor
    |> Task.Supervisor.async_stream(
      [nil | @parameters.variants(config)],
      fn variant ->
        {variant, config |> Layout.generate(variant) |> then_fn.(config)}
      end
    )
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.split(1)
    |> then(fn {[{nil, default}], variants} -> {default, Map.new(variants)} end)
  end

  defp get_config(screen_id, opts),
    do: Keyword.get_lazy(opts, :pending_config, fn -> @config_cache.screen(screen_id) end)

  @spec layout_to_data(Layout.t(), Screen.t()) :: t()
  defp layout_to_data(layout, config) do
    layout |> resolve_paging(config) |> serialize()
  end

  @spec layout_to_simulation_data(Layout.t(), Screen.t()) :: simulation_data()
  defp layout_to_simulation_data(layout, config) do
    %{
      full_page: layout |> resolve_paging(config) |> serialize(),
      flex_zone: layout |> serialize_paged_slots(config.app_id)
    }
  end

  defp resolve_paging(layout, config),
    do: Layout.resolve_paging(layout, @parameters.refresh_rate(config))

  @spec serialize(Layout.non_paged()) :: map() | nil
  def serialize({layout, instance_map, paging_metadata}) do
    serialized_instance_map =
      instance_map
      |> Enum.map(fn {slot_id, instance} -> {slot_id, serialize_instance_with_type(instance)} end)
      |> Enum.into(%{})

    Template.position_widget_instances(layout, serialized_instance_map, paging_metadata)
  end

  defp serialize_paged_slots({layout, instance_map}, app_id) do
    instance_map
    |> Map.filter(fn
      {slot_id, _instance} when is_paged_slot_id(slot_id) -> true
      _ -> false
    end)
    |> Enum.group_by(
      &paged_slot_key(&1, app_id),
      fn {paged_slot_id, instance} -> {Template.unpage(paged_slot_id), instance} end
    )
    # %{page_index => [{slot_id, instance}]}
    |> Enum.map(fn {page_index, instances} -> {page_index, Map.new(instances)} end)
    # %{page_index => %{slot_id => instance}}
    |> Enum.sort_by(fn {page_index, _} -> page_index end)
    # [{page_index, %{slot_id => instance}}]
    |> Enum.map(fn {_page_index, page_data} ->
      Enum.into(page_data, %{}, fn {slot_id, instance} ->
        {slot_id, serialize_instance_with_type(instance)}
      end)
    end)

    # Now we have a list of serialized page data, sorted by page index
    # [%{slot_id => serialized_instance}]
    # We just need to add the type of the containing slot
    |> Enum.map(fn instance_map ->
      slot_ids = Map.keys(instance_map)
      containing_slot_id = get_containing_slot(layout, slot_ids)
      Map.put(instance_map, :type, containing_slot_id)
    end)
  end

  defp serialize_instance_with_type(instance) do
    instance
    |> WidgetInstance.serialize()
    |> Map.merge(%{type: WidgetInstance.widget_type(instance)})
  end

  @spec get_containing_slot(Template.layout(), list(Template.non_paged_slot_id())) ::
          Template.non_paged_slot_id()

  defp get_containing_slot(layout, target_slot_ids)

  defp get_containing_slot(slot_id, _target_slot_ids) when is_slot_id(slot_id) do
    nil
  end

  defp get_containing_slot({_slot_id, {layout_type, children}}, target_slot_ids) do
    # if all children are "leaf nodes", look for the target_slot_id in the children.
    if Enum.all?(children, &is_slot_id(&1)) do
      match =
        children
        |> Enum.map(&Template.unpage/1)
        |> MapSet.new()
        |> MapSet.equal?(MapSet.new(target_slot_ids))

      # if found, return it.
      # otherwise, go down a level.
      if match,
        do: layout_type,
        else: Enum.find_value(children, &get_containing_slot(&1, target_slot_ids))
    else
      # some children are not "leaf nodes". go down a level.
      Enum.find_value(children, &get_containing_slot(&1, target_slot_ids))
    end
  end

  def update_visible_alerts(_, _, %Screen{hidden_from_screenplay: true}, _opts), do: :ok

  def update_visible_alerts({_layout, instance_map}, screen_id, _config, opts) do
    if Keyword.get(opts, :update_visible_alerts?, false) do
      alert_ids =
        instance_map
        |> Map.values()
        |> Enum.flat_map(&AlertsWidget.alert_ids/1)

      ScreensByAlert.put_data(screen_id, alert_ids)
    end

    :ok
  end

  defp paged_slot_key({paged_slot_id, _}, :pre_fare_v2), do: Template.get_slot_id(paged_slot_id)
  defp paged_slot_key({paged_slot_id, _}, _), do: Template.get_page(paged_slot_id)
end
