defmodule Screens.V2.DisruptionDiagram.Model do
  @moduledoc """
  Functions to generate a disruption diagram from a `LocalizedAlert`.
  """

  alias Screens.V2.LocalizedAlert
  alias Screens.V2.DisruptionDiagram.Validator
  alias Screens.V2.DisruptionDiagram.Builder
  alias Screens.Stops.Stop

  import LocalizedAlert, only: [is_localized_alert: 1]

  # We don't need to define any new struct for the diagram's source data--
  # we can use any map/struct that satisfies LocalizedAlert.t().
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
          effect_region_slot_index_range: {non_neg_integer(), non_neg_integer()},
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

  @max_closure_count 8

  # The max number of stops allowed in the gap when it needs to be collapsed
  @collapsed_gap_max 2

  @doc "Produces a JSON-serializable map representing the disruption diagram."
  @spec serialize(t()) :: {:ok, serialized_response()} | {:error, reason :: String.t()}
  def serialize(localized_alert) when is_localized_alert(localized_alert) do
    with :ok <- Validator.validate(localized_alert),
         {:ok, data} <- do_serialize(localized_alert) do
      {:ok, data}
    end
  rescue
    error ->
      error_string =
        Exception.message(error) <> "\n\n" <> Exception.format_stacktrace(__STACKTRACE__)

      {:error, "Exception raised during serialization:\n\n#{error_string}"}
  end

  defp do_serialize(localized_alert) do
    with {:ok, builder} <- Builder.new(localized_alert) do
      line = Builder.line(builder)

      {:ok, serialize_by_line(line, builder)}
    end
  end

  @spec serialize_by_line(line_color(), Builder.t()) :: serialized_response()
  # The Blue Line is the simplest case. We always show all stops, starting with Bowdoin.
  defp serialize_by_line(:blue, builder) do
    # The default stop sequence starts with Wonderland, so we need to put the stops in reverse order
    # to have Bowdoin appear first on the diagram.
    builder
    |> Builder.reverse()
    |> Builder.serialize()
  end

  # For the Green Line, we need to reverse the diagram in certain cases.
  defp serialize_by_line(:green, builder) do
    builder
    |> maybe_reverse_gl()
    |> fit_regions()
    |> Builder.serialize()
  end

  # Red Line and Orange Line diagrams never need to be reversed--we just need to fit regions.
  defp serialize_by_line(_orange_or_red, builder) do
    builder
    |> fit_regions()
    |> Builder.serialize()
  end

  defp fit_regions(builder) do
    with :unchanged <- fit_closure_region(builder),
         :unchanged <- fit_gap_region(builder),
         :unchanged <- pad_slots(builder) do
      builder
    else
      {:done, builder} -> builder
    end
  end

  # The diagram needs to be flipped whenever it's not a GLX-only alert.
  defp maybe_reverse_gl(builder) do
    is_glx_branch = builder.metadata.branch in [:d, :e]

    if is_glx_branch and glx_only_alert?(builder) do
      builder
    else
      Builder.reverse(builder)
    end
  end

  defp glx_only_alert?(builder) do
    diagram_contains_glx =
      Aja.Enum.any?(builder.sequence, fn
        %Builder.StopSlot{} = stop_data -> Stop.on_glx?(stop_data.id)
        _ -> false
      end)

    copley_index =
      Aja.Enum.find_index(builder.sequence, fn
        %Builder.StopSlot{id: "place-coecl"} -> true
        _ -> false
      end)

    no_stops_west_of_copley =
      case copley_index do
        nil -> true
        # If Copley is in the sequence, it can only be the last stop
        i -> i == Aja.Vector.size(builder.sequence) - 1
      end

    diagram_contains_glx and no_stops_west_of_copley
  end

  defp fit_closure_region(builder) do
    current_closure_count = Builder.closure_count(builder)

    with true <- current_closure_count > @max_closure_count,
         target_closure_slots = 12 - min_non_closure_slots(builder),
         {:lt, true} <- {:lt, target_closure_slots < current_closure_count} do
      builder =
        builder
        |> Builder.omit_stops(:closure, target_closure_slots)
        |> minimize_gap()

      {:done, builder}
    else
      {:lt, false} ->
        target_closure_slots = 12 - min_non_closure_slots(builder)

        # TODO: Remove this and the extra code producing this {:lt, false} pattern
        # once we're confident that this is always the right way to handle scenarios
        # where the math works out this way
        IO.puts(
          "fit_closure_region: target_count (#{target_closure_slots}) >= current_count (#{current_closure_count}), doing nothing"
        )

        :unchanged

      _ ->
        :unchanged
    end
  end

  defp minimize_gap(builder) do
    current_gap_count = Builder.gap_count(builder)
    target_gap_slots = min_gap(builder)

    if target_gap_slots < current_gap_count do
      Builder.omit_stops(builder, :gap, target_gap_slots)
    else
      builder
    end
  end

  defp fit_gap_region(builder) do
    current_gap_count = Builder.gap_count(builder)

    with true <- current_gap_count >= 3,
         taken_slots = non_gap_slots(builder),
         baseline = baseline_slots(Builder.closure_count(builder)),
         target_gap_slots = baseline - taken_slots,
         {:lt, true} <- {:lt, target_gap_slots < current_gap_count} do
      builder = Builder.omit_stops(builder, :gap, target_gap_slots)

      {:done, builder}
    else
      {:lt, false} ->
        taken_slots = non_gap_slots(builder)
        baseline = baseline_slots(Builder.closure_count(builder))
        target_gap_slots = baseline - taken_slots

        IO.puts(
          "fit_gap_region: target_count (#{target_gap_slots}) >= current_count (#{current_gap_count}), doing nothing"
        )

        :unchanged

      _ ->
        :unchanged
    end
  end

  defp pad_slots(builder) do
    current_slot_count = Builder.slot_count(builder)

    if current_slot_count < @minimum_slot_count do
      {:done, Builder.add_slots(builder, @minimum_slot_count - current_slot_count)}
    else
      :unchanged
    end
  end

  defp min_non_closure_slots(builder) do
    Builder.end_count(builder) + Builder.current_location_count(builder) + min_gap(builder)
  end

  # Number of slots used by all regions except the gap, when it doesn't get minimized
  defp non_gap_slots(builder) do
    Builder.end_count(builder) + Builder.closure_count(builder) +
      Builder.current_location_count(builder)
  end

  # The minimum possible size of the gap region.
  defp min_gap(builder) do
    min(Builder.gap_count(builder), @collapsed_gap_max)
  end

  for {closure, baseline} <- %{2 => 10, 3 => 10, 4 => 12, 5 => 12, 6 => 14, 7 => 14, 8 => 14} do
    defp baseline_slots(unquote(closure)), do: unquote(baseline)
  end
end

# TODO: What if there is a station closure with 3 stops very far apart.
#       How to avoid omitting the bypassed station in the middle while shrinking closure region
#       Maybe avoid omitting any stops with disrupted?: true
#
#       Complicating factor: The removed stop in the middle could also be the home stop, which
#       breaks stuff

# TODO: One-stop continuous alerts? Are those possible, could they ever make sense?
# - One-stop shuttle: No...
# - One-stop suspension: Maybe? Trains in either direction stop at the station but turn around

# TODO: Original code at the start of Builder.new is hot garbo.
# Make it more resilient--should get stop/route stuff based on the route that fully contains
# informed stops ++ home stop (since really we only care about getting all the info we need to draw the diagram between them)
