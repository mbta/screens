defmodule Screens.V2.DisruptionDiagram.Model do
  @moduledoc """
  Functions to generate a disruption diagram from a `LocalizedAlert`.
  """

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.DisruptionDiagram.Model.Validator
  alias Screens.V2.DisruptionDiagram.Model.AnnotatedStopSequence
  alias Screens.Stops.Stop

  import LocalizedAlert, only: [is_localized_alert: 1]

  require Logger

  # We don't need to define any new struct for the diagram's source data--
  # we can just use any map/struct that satisfies LocalizedAlert.t().
  @type t :: LocalizedAlert.t()

  @type serialized_response :: continuous_disruption_diagram() | discrete_disruption_diagram()

  @type continuous_disruption_diagram :: %{
          effect: :shuttle | :suspension,
          # A 2-element list, giving indices of the effect region's *boundary stops*, inclusive.
          # For example in this scenario:
          #     0     1     2     3     4     5     6     7     8
          #    <= === O ========= O - - X - - X - - X - - O === O
          #                       |---------range---------|
          # The range is [3, 7].
          #
          # SPECIAL CASE:
          # If the range starts at 0 or ends at the last element of the array,
          # then the symbol for that terminal stop should use the appropriate
          # disruption symbol, not the "normal service" symbol.
          # For example if the range is [0, 5], the left end of the
          # diagram should use a disruption symbol:
          #     0     1     2     3     4     5     6     7     8
          #     X - - X - - X - - X - - X - - O ========= O === =>
          #     |------------range------------|
          effect_region_slot_index_range: list(non_neg_integer()),
          line: line_color(),
          current_station_slot_index: non_neg_integer(),
          # First and last elements of the list are `end_slot`s, middle elements are `middle_slot`s.
          slots: list(slot())
        }

  @type discrete_disruption_diagram :: %{
          effect: :station_closure,
          closed_station_slot_indices: list(non_neg_integer()),
          line: line_color(),
          current_station_slot_index: non_neg_integer(),
          # First and last elements of the list are `end_slot`s, middle elements are `middle_slot`s.
          slots: list(slot())
        }

  @type slot :: end_slot() | middle_slot()

  @type end_slot :: %{
          type: :arrow | :terminal,
          label_id: end_label_id()
        }

  @type middle_slot :: %{
          label: label(),
          show_symbol: boolean()
        }

  @type label :: label_map() | ellipsis()

  @type label_map :: %{full: String.t(), abbrev: String.t()}

  # Literally the string "…", but you can't use string literals as types in elixir
  @type ellipsis :: String.t()

  # End labels have hardcoded presentation, so we just send an ID for the client to use in
  # a lookup.
  #
  # TBD what these IDs will look like. We might just use parent station IDs.
  #
  # The rest of the labels' presentations are computed based on the height of the end labels,
  # so we can send actual text for those--it will be dynamically resized to fit.
  @type end_label_id :: String.t()

  @type line_color :: :blue | :orange | :red | :green

  @minimum_slot_count 6

  # The maximum number of slots that the gap component can take up
  @max_gap_count 2

  @doc "Produces a JSON-serializable map representing the disruption diagram."
  # TODO Remove nil return type
  @spec serialize(t()) :: serialized_response() | nil
  def serialize(localized_alert) when is_localized_alert(localized_alert) do
    case Validator.validate(localized_alert) do
      :ok ->
        do_serialize(localized_alert)

      :error ->
        raise "attempted to generate a disruption diagram for an incompatible LocalizedAlert"
    end
  end

  defp do_serialize(localized_alert) do
    annotated_sequence = AnnotatedStopSequence.new(localized_alert)

    line = AnnotatedStopSequence.line(annotated_sequence)

    serialize_by_line(line, annotated_sequence)
  end

  @max_closure_count 8

  @spec serialize_by_line(line_color(), AnnotatedStopSequence.t()) :: serialized_response()
  # The Blue Line is the simplest case. We always show all stops, starting with Bowdoin.
  defp serialize_by_line(:blue, annotated_sequence) do
    # The default stop sequence starts with Wonderland, so we need to put the stops in reverse order
    # to have Bowdoin appear first on the diagram.
    annotated_sequence
    |> AnnotatedStopSequence.reverse_stops()
    |> serialize_annotated()
  end

  # There's some special logic for the Green Line.
  defp serialize_by_line(:green, annotated_sequence) do
    nil
  end

  defp serialize_by_line(_orange_or_red, annotated_sequence) do
    annotated_sequence
    |> fit_closure_region()
  end

  # TODO: What if home stop is in the stops to omit?
  defp fit_closure_region(annotated_sequence) do
    if AnnotatedStopSequence.closure_count(annotated_sequence) > 8 do
      # The number of closure slots we want left after the omission.
      # This includes one slot for the omitted stations, labeled with "...via $STOPS"
      target_closure_slots = 12 - min_non_closure_slots(annotated_sequence)

      AnnotatedStopSequence.omit_stops(
        annotated_sequence,
        :closure,
        target_closure_slots,
        &get_closure_omission_label(AnnotatedStopSequence.line(annotated_sequence), &1, false)
      )
    else
      annotated_sequence
    end
  end

  defp get_closure_omission_label(line, omitted_stop_ids, ends_at_gov_ctr?)

  defp get_closure_omission_label(:green, omitted_stop_ids, false) do
    if "place-gover" in omitted_stop_ids,
      do: %{full: "…via Government Center", abbrev: "…via Gov't Ctr"},
      else: "…"
  end

  defp get_closure_omission_label(:green, omitted_stop_ids, true) do
    [
      if("place-kencl" in omitted_stop_ids, do: "Kenmore"),
      if("place-coecl" in omitted_stop_ids, do: "Copley")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" & ")
    |> case do
      "" ->
        "…"

      stop_names ->
        text = "…via #{stop_names}"
        %{full: text, abbrev: text}
    end
  end

  defp get_closure_omission_label(:red, omitted_stop_ids, _) do
    if "place-dwnxg" in omitted_stop_ids,
      do: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
      else: "…"
  end

  defp get_closure_omission_label(:orange, omitted_stop_ids, _) do
    if "place-dwnxg" in omitted_stop_ids,
      do: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
      else: "…"
  end

  # get_closure_omission_label should never be called for Blue Line diagrams.

  defp min_non_closure_slots(annotated_sequence) do
    AnnotatedStopSequence.end_count(annotated_sequence) +
      AnnotatedStopSequence.current_location_count(annotated_sequence) +
      AnnotatedStopSequence.min_gap(annotated_sequence)
  end

  defp serialize_annotated(annotated_sequence) do
    import AnnotatedStopSequence

    base_data = %{
      effect: annotated_sequence |> effect(),
      line: annotated_sequence |> line(),
      current_station_slot_index: annotated_sequence |> current_station_index(),
      slots: annotated_sequence |> to_slots()
    }

    if base_data.effect == :station_closure do
      Map.put(
        base_data,
        :closed_station_slot_indices,
        annotated_sequence |> disrupted_stop_indices()
      )
    else
      range =
        annotated_sequence
        |> disrupted_stop_indices()
        |> then(&[List.first(&1), List.last(&1)])

      Map.put(base_data, :effect_region_slot_index_range, range)
    end
  end
end

# TODO: Reverse stop order for all GL diagrams, except when disruption is on GLX

# TODO: Create a function that determines terminal label from a set of omitted stops

# TODO: Define a representation for omitted stops

# TODO: Create a function that determines mid-route label from a set of omitted stops
#       - via STOP:
#         - Red Line: DTX
#         - Orange Line: DTX
#         - Green Line: Gov Ctr
#         - Green Line when the diagram ends at Gov Ctr:
#           - Kenmore & Copley (whichever are omitted)
