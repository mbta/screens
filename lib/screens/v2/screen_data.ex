defmodule Screens.V2.ScreenData do
  @moduledoc false

  require Logger

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template
  alias Screens.V2.WidgetInstance

  @type screen_id :: String.t()
  @type config :: Screens.Config.Screen.t()
  @type candidate_generator :: module()
  @type candidate_instances :: list(WidgetInstance.t())
  @type selected_instances_map :: %{Template.slot_id() => WidgetInstance.t()}
  @type serializable_map :: %{type: atom()}

  @app_id_to_candidate_generator %{
    bus_eink: CandidateGenerator.BusEink,
    gl_eink_double: CandidateGenerator.GlEinkDouble,
    gl_eink_single: CandidateGenerator.GlEinkSingle,
    solari: CandidateGenerator.Solari,
    dup: CandidateGenerator.Dup,
    bus_shelter: CandidateGenerator.BusShelter
  }

  @app_id_to_refresh_rate %{
    bus_eink: 30,
    gl_eink_double: 30,
    gl_eink_single: 30,
    solari: 15,
    dup: nil,
    bus_shelter: 15
  }

  @spec by_screen_id(screen_id()) :: serializable_map()
  def by_screen_id(screen_id) do
    config = get_config(screen_id)
    candidate_generator = get_candidate_generator(config)
    screen_template = candidate_generator.screen_template()
    candidate_instances = candidate_generator.candidate_instances(config)

    screen_template
    |> pick_instances(candidate_instances)
    |> serialize(get_refresh_rate(config))
  end

  @spec get_config(screen_id()) :: config()
  def get_config(screen_id) do
    Screens.Config.State.screen(screen_id)
  end

  @spec get_candidate_generator(config()) :: candidate_generator()
  def get_candidate_generator(%Screens.Config.Screen{app_id: app_id}) do
    Map.get(@app_id_to_candidate_generator, app_id)
  end

  @spec get_refresh_rate(config()) :: pos_integer() | nil
  def get_refresh_rate(%Screens.Config.Screen{app_id: app_id}) do
    Map.get(@app_id_to_refresh_rate, app_id)
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

    placements = Enum.reduce(prioritized_instances, candidate_placements, &place_instance/2)

    # N.B. If there are multiple templates returned, log it, then arbitrarily select the first.
    valid_templates = Map.keys(placements)

    _ =
      if length(valid_templates) > 1 do
        Logger.info("[found multiple valid templates]")
      end

    selected_template = hd(valid_templates)
    selected_instances = Map.get(placements, selected_template)
    {_, selected_layout} = selected_template

    {selected_layout, selected_instances}
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
          chosen_slot = get_first_slot(t, instance_slots) |> IO.inspect(label: "👉")

          updated_placement =
            placements
            |> Map.get(t)
            |> Map.put(chosen_slot, instance)

          {slots, layout} = t
          new_t = {(slots -- [chosen_slot]) |> IO.inspect(label: "🌝"), layout}

          {new_t, updated_placement}
        end)
        |> Enum.into(%{})
    end
  end

  defp get_valid_templates(templates, instance_slots) do
    Enum.filter(templates, &template_is_placeable?(&1, instance_slots))
    |> IO.inspect(label: "🍕 valid templates for #{inspect(instance_slots)}")
  end

  defp get_first_slot(template, instance_slots) do
    template
    |> get_valid_slots(instance_slots)
    |> hd()
    |> IO.inspect(label: "❇️ first slot for #{inspect(instance_slots)}")
  end

  defp template_is_placeable?(template, instance_slots) do
    matching_slots = get_valid_slots(template, instance_slots)
    length(matching_slots) > 0
  end

  defp get_valid_slots(template, instance_slots) do
    {template_slots, _} = template

    # N.B. The slots are sorted so that paged regions have their earlier pages filled first.
    # e.g. [:footer, :header, {0, :flex_zone}, {1, :flex_zone}]
    # (though usually we wouldn't get a mix of paged an non-paged slots for a given widget instance)
    sorted_slot_list_intersection(template_slots, instance_slots)
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
    |> Enum.sort(&<=/2)
  end

  @spec serialize({Template.layout(), selected_instances_map()}, integer()) :: serializable_map()
  def serialize({layout, instance_map}, _refresh_rate) do
    serialized_instance_map =
      instance_map
      |> Enum.map(fn {slot_id, instance} -> {slot_id, serialize_instance_with_type(instance)} end)
      |> Enum.into(%{})

    IO.inspect(layout, label: "layout")
    IO.inspect(serialized_instance_map, label: "serialized_instance_map")
    Template.position_widget_instances(layout, serialized_instance_map)
  end

  defp serialize_instance_with_type(instance) do
    instance
    |> WidgetInstance.serialize()
    |> Map.merge(%{type: WidgetInstance.widget_type(instance)})
  end
end
