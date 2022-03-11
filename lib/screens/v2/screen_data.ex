defmodule Screens.V2.ScreenData do
  @moduledoc false

  require Logger

  alias Screens.Util
  alias Screens.V2.ScreenData.Parameters
  alias Screens.V2.Template
  alias Screens.V2.WidgetInstance

  import Screens.V2.Template.Guards

  @type screen_id :: String.t()
  @type config :: Screens.Config.Screen.t()
  @type candidate_instances :: list(WidgetInstance.t())
  @type selected_instances_map :: %{Template.slot_id() => WidgetInstance.t()}
  @type non_paged_selected_instances_map :: %{Template.non_paged_slot_id() => WidgetInstance.t()}
  @type serializable_map :: %{type: atom()}
  @type response_map :: %{
          data: serializable_map() | nil,
          force_reload: boolean(),
          disabled: boolean()
        }
  @type paging_metadata :: %{
          Template.non_paged_slot_id() =>
            {page_index :: non_neg_integer(), num_pages :: pos_integer()}
        }

  @spec outdated_response() :: response_map()
  def outdated_response, do: response(force_reload: true)

  @spec disabled_response() :: response_map()
  def disabled_response, do: response(disabled: true)

  @spec by_screen_id(screen_id()) :: response_map()
  def by_screen_id(screen_id) do
    config = get_config(screen_id)
    refresh_rate = Parameters.get_refresh_rate(config)

    config
    |> fetch_data()
    |> resolve_paging(refresh_rate)
    |> serialize()
  end

  @spec fetch_data(Screens.Config.Screen.t()) :: {Template.layout(), selected_instances_map()}
  def fetch_data(config) do
    candidate_generator = Parameters.get_candidate_generator(config)
    screen_template = candidate_generator.screen_template()

    candidate_instances =
      config
      |> candidate_generator.candidate_instances()
      |> Enum.filter(&WidgetInstance.valid_candidate?/1)

    pick_instances(screen_template, candidate_instances)
  end

  @spec get_config(screen_id()) :: config()
  def get_config(screen_id) do
    Screens.Config.State.screen(screen_id)
  end

  @spec pick_instances(Template.template(), candidate_instances()) ::
          {Template.layout(), selected_instances_map()}
  def pick_instances(screen_template, candidate_instances) do
    prioritized_instances = Enum.sort_by(candidate_instances, &WidgetInstance.priority/1)

    # N.B. Each template can place each instance it contains in a different place, so we need to
    # store a mapping from slot_id to instance for each template.
    candidate_placements =
      screen_template
      |> Template.slot_combinations()
      |> Enum.map(fn t -> {t, %{}} end)
      |> Enum.into(%{})

    {{_, {slot_id, {layout_type, _children}} = selected_layout}, selected_instances} =
      prioritized_instances
      |> Enum.reduce(candidate_placements, &place_instance/2)
      |> log_mismatched_placement_widgets()
      |> select_best_placement()

    filtered_children =
      selected_layout
      |> filter_empty_slots(Map.keys(selected_instances))

    {{slot_id, {layout_type, filtered_children}}, selected_instances}
  end

  defp place_instance(instance, placements) do
    instance_slots = WidgetInstance.slot_names(instance)
    live_templates = Map.keys(placements)
    placeable_templates = get_valid_templates(live_templates, instance_slots)

    case placeable_templates do
      [] ->
        # If none of the remaining templates can hold the current instance, don't include that
        # instance, and continue with the same live templates and placements.
        placements

      _ ->
        # If at least one of the remaining templates can hold the current instance, throw out all
        # templates which can't. For those which can, choose a valid slot and place the instance
        # there, adding it to the slot_id => instance mapping for that template, and removing it
        # from the list of unoccupied slot_ids.
        placeable_templates
        |> Enum.map(fn t ->
          chosen_slot = get_first_slot(t, instance_slots)

          updated_placement =
            placements
            |> Map.get(t)
            |> Map.put(chosen_slot, instance)

          {slots, layout} = t
          new_t = {slots -- [chosen_slot], layout}

          {new_t, updated_placement}
        end)
        |> Enum.into(%{})
    end
  end

  defp get_valid_templates(templates, instance_slots) do
    Enum.filter(templates, &template_is_placeable?(&1, instance_slots))
  end

  defp get_first_slot(template, instance_slots) do
    template
    |> get_valid_slots(instance_slots)
    |> hd()
  end

  defp template_is_placeable?(template, instance_slots) do
    matching_slots = get_valid_slots(template, instance_slots)
    length(matching_slots) > 0
  end

  defp get_valid_slots(template, instance_slots) do
    {template_slots, _} = template

    # N.B. The slots are sorted so that paged regions have their earlier pages filled first.
    # e.g. [{0, :paged_region1}, {0, :paged_region2}, {1, :paged_region1}, {1, :paged_region2}]
    sorted_slot_list_intersection(template_slots, instance_slots)
  end

  defp log_mismatched_placement_widgets(placements) when map_size(placements) < 2, do: placements

  defp log_mismatched_placement_widgets(placements) do
    [first_widget_set | widget_sets] =
      placements
      |> Map.values()
      |> Enum.map(&Map.values/1)
      |> Enum.map(&MapSet.new/1)

    _ =
      if Enum.any?(widget_sets, &(not MapSet.equal?(first_widget_set, &1))) do
        Logger.info("[mismatched widget placements]")
      end

    placements
  end

  defp select_best_placement(placements) when map_size(placements) < 2 do
    placements
    |> Map.to_list()
    |> hd()
  end

  defp select_best_placement(placements) do
    # When multiple valid placements are produced due to paging, prefer the one
    # that has higher-priority instances placed on earlier pages.
    # Each placement is compared by sorting the mapping by instance priority,
    # then mapping each entry to its slot's page index (or nil if not paged).
    # Example min_by comparison key: [nil, 0, 1, 0, 0]
    placements
    |> Enum.min_by(fn {_, slot_to_instance} ->
      slot_to_instance
      |> Enum.sort_by(fn {_, instance} -> WidgetInstance.priority(instance) end)
      |> Enum.map(fn
        {{page_index, _slot}, _} -> page_index
        {_slot, _} -> nil
      end)
    end)
  end

  @spec sorted_slot_list_intersection(
          list(Template.slot_id()),
          list(Template.non_paged_slot_id())
        ) ::
          list(Template.slot_id())
  def sorted_slot_list_intersection(template_slots, instance_slots) do
    for t_slot <- template_slots,
        i_slot <- instance_slots,
        Template.slots_match?(t_slot, i_slot) do
      t_slot
    end
    |> Enum.sort(&Template.slot_precedes_or_equal?/2)
  end

  @spec resolve_paging(
          {Template.layout(), selected_instances_map()},
          integer() | nil,
          DateTime.t()
        ) ::
          {Template.non_paged_layout(), non_paged_selected_instances_map(), paging_metadata()}
  def resolve_paging(layout_and_instances, refresh_rate, now \\ DateTime.utc_now())

  def resolve_paging(layout_and_instances, nil, _now) do
    Tuple.append(layout_and_instances, %{})
  end

  def resolve_paging({layout, instance_map}, refresh_rate, now) do
    {unpaged_layout, selected_paged_slot_ids, paging_metadata} =
      choose_visible_slot_ids(layout, refresh_rate, now)

    # Now filter instance map by set of paged slot ids, then unpage
    instance_map =
      instance_map
      |> Enum.filter(fn
        {slot_id, _instance} when is_paged_slot_id(slot_id) ->
          slot_id in selected_paged_slot_ids

        _ ->
          true
      end)
      |> Enum.map(fn {slot_id, instance} -> {Template.unpage(slot_id), instance} end)
      |> Enum.into(%{})

    {unpaged_layout, instance_map, paging_metadata}
  end

  defp select_page_index(num_pages, refresh_rate, now) do
    seconds_since_midnight = now.hour * 60 * 60 + now.minute * 60 + now.second
    periods_since_midnight = div(seconds_since_midnight, refresh_rate)
    rem(periods_since_midnight, num_pages)
  end

  # Function to remove slots from the layout if there are no candidates available to populate it
  # Specifically added to help introduce variable paging
  defp filter_empty_slots({_slot_id, {_layout_type, children}}, selected_instances_slots) do
    children
    |> Enum.map(fn
      # Static slots: :main_content, :header, etc.
      slot_id when is_atom(slot_id) ->
        if slot_id in selected_instances_slots do
          slot_id
        end

      # Paged slots: :flex_zone
      nested_child when is_paged_slot_id(nested_child) ->
        if nested_child in selected_instances_slots do
          nested_child
        end

      # A nested layout. Take the nested layout and feed it back into this function to process its children.
      {slot_id, {layout_type, _children}} = nested_layout ->
        case filter_empty_slots(nested_layout, selected_instances_slots) do
          [nil] ->
            nil

          child ->
            {slot_id, {layout_type, child}}
        end
    end)
    # Remove all nil/empty pages from the original children.
    |> Enum.filter(fn
      nil -> false
      {_, {_, []}} -> false
      _ -> true
    end)
  end

  @spec choose_visible_slot_ids(Template.layout(), integer(), DateTime.t()) ::
          {Template.non_paged_layout(), MapSet.t(Template.paged_slot_id()), paging_metadata()}
  defp choose_visible_slot_ids(layout, refresh_rate, now)

  defp choose_visible_slot_ids(slot_id, _refresh_rate, _now) when is_non_paged_slot_id(slot_id) do
    {slot_id, MapSet.new(), %{}}
  end

  defp choose_visible_slot_ids({slot_id, {layout_type, children}}, refresh_rate, now) do
    {children, selected_paged_slot_ids, paging_metadata} =
      choose_visible_slot_ids(children, refresh_rate, now)

    {{slot_id, {layout_type, children}}, selected_paged_slot_ids, paging_metadata}
  end

  defp choose_visible_slot_ids(layouts, refresh_rate, now) when is_list(layouts) do
    {selected_paged_slot_ids, paging_metadata_entries} =
      layouts
      |> Enum.filter(fn
        layout when is_paged(layout) -> true
        _ -> false
      end)
      |> Enum.group_by(&Template.unpage/1, &Template.get_page/1)
      |> Enum.map(fn {slot_id, page_indexes} -> {slot_id, Enum.max(page_indexes) + 1} end)
      |> Enum.map(fn {slot_id, num_pages} ->
        selected_page_index = select_page_index(num_pages, refresh_rate, now)
        selected_paged_slot_id = {selected_page_index, slot_id}
        paging_metadata_entry = {slot_id, {selected_page_index, num_pages}}

        {selected_paged_slot_id, paging_metadata_entry}
      end)
      |> Enum.unzip()

    paging_metadata = Map.new(paging_metadata_entries)

    selected_layouts =
      Enum.filter(layouts, fn
        layout when is_paged(layout) -> Template.get_slot_id(layout) in selected_paged_slot_ids
        _ -> true
      end)

    # Now we have the list of layouts to keep, but still need to unpage them
    # and create a set of the paged slot ids to keep in the instance map.
    # We also need to recurse on non-paged layouts in case they contain paging deeper down.
    {unpaged_layouts, paged_slot_sets, paging_metadata_maps} =
      selected_layouts
      |> Enum.map(fn
        layout when is_paged(layout) ->
          layout
          |> unpage_layout_and_track_slots()
          |> Tuple.append(%{})

        layout ->
          choose_visible_slot_ids(layout, refresh_rate, now)
      end)
      |> Util.unzip3()

    paged_slot_set = Enum.reduce(paged_slot_sets, &MapSet.union/2)

    paging_metadata = Enum.reduce(paging_metadata_maps, paging_metadata, &Map.merge/2)

    {unpaged_layouts, paged_slot_set, paging_metadata}
  end

  defp unpage_layout_and_track_slots(slot_id) when is_paged_slot_id(slot_id) do
    {Template.unpage(slot_id), MapSet.new([slot_id])}
  end

  defp unpage_layout_and_track_slots({slot_id, {layout_type, children}})
       when is_paged_slot_id(slot_id) do
    {children, paged_slot_sets} =
      children
      |> Enum.map(&unpage_layout_and_track_slots/1)
      |> Enum.unzip()

    paged_slot_set = Enum.reduce(paged_slot_sets, &MapSet.union/2)

    {{Template.unpage(slot_id), {layout_type, children}}, paged_slot_set}
  end

  defp unpage_layout_and_track_slots(non_paged_layout) do
    {non_paged_layout, MapSet.new()}
  end

  @spec serialize(
          {Template.non_paged_layout(), non_paged_selected_instances_map(), paging_metadata()}
        ) :: response_map()
  def serialize({layout, instance_map, paging_metadata}) do
    serialized_instance_map =
      instance_map
      |> Enum.map(fn {slot_id, instance} -> {slot_id, serialize_instance_with_type(instance)} end)
      |> Enum.into(%{})

    data = Template.position_widget_instances(layout, serialized_instance_map, paging_metadata)
    response(data: data)
  end

  defp serialize_instance_with_type(instance) do
    instance
    |> WidgetInstance.serialize()
    |> Map.merge(%{type: WidgetInstance.widget_type(instance)})
  end

  @spec response(keyword()) :: response_map()
  defp response(fields) do
    %{
      data: Keyword.get(fields, :data, nil),
      force_reload: Keyword.get(fields, :force_reload, false),
      disabled: Keyword.get(fields, :disabled, false)
    }
  end
end
