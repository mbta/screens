defmodule Screens.V2.ScreenData do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type screen_id :: String.t()
  @type config :: :ok
  @type candidate_generator :: module()
  @type candidate_templates :: :ok
  @type candidate_instances :: :ok
  @type selected_template :: :ok
  @type selected_widgets :: :ok
  @type selected :: {selected_template, selected_widgets}
  @type serializable_map :: :ok

  @spec by_screen_id(screen_id()) :: serializable_map()
  def by_screen_id(screen_id) do
    config = get_config(screen_id)
    candidate_generator = get_candidate_generator(config)
    candidate_templates = candidate_generator.candidate_templates()
    candidate_instances = candidate_generator.candidate_instances(config)

    candidate_templates
    |> pick_instances(candidate_instances)
    |> serialize()
  end

  @spec get_config(screen_id()) :: config()
  def get_config(_screen_id) do
    :ok
  end

  @spec get_candidate_generator(config()) :: candidate_generator()
  def get_candidate_generator(:ok) do
    Screens.V2.CandidateGenerator.BusShelter
  end

  @spec pick_instances(candidate_templates(), candidate_instances()) :: selected()
  def pick_instances(candidate_templates, candidate_instances) do
    prioritized_instances = Enum.sort_by(candidate_instances, &WidgetInstance.priority/1)

    # N.B. Each template can place each instance it contains in a different place, so we need to
    # store a mapping from slot_id to instance for each template.
    candidate_placements =
      candidate_templates
      |> Enum.map(fn t -> {t, %{}} end)
      |> Enum.into(%{})

    placements = Enum.reduce(prioritized_instances, candidate_placements, &reducer/2)

    # N.B. If there are multiple templates returned, arbitrarily select the first.
    selected_template =
      placements
      |> Map.keys()
      |> Enum.at(0)

    selected_instances = Map.get(placements, selected_template)
    {_, selected_layout} = selected_template

    {selected_layout, selected_instances}
  end

  defp reducer(instance, placements) do
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

  defp get_valid_slots(template, instance_slots) do
    {template_slots, _} = template
    template_slots -- template_slots -- instance_slots
  end

  defp get_first_slot(template, instance_slots) do
    [slot | _] = get_valid_slots(template, instance_slots)
    slot
  end

  defp template_is_placeable?(template, instance_slots) do
    matching_slots = get_valid_slots(template, instance_slots)
    length(matching_slots) > 0
  end

  @spec serialize(selected()) :: serializable_map()
  def serialize({:ok, :ok}) do
    :ok
  end
end
