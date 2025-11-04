defmodule Screens.V2.DisruptionDiagram.Model do
  @moduledoc """
  Functions to generate a disruption diagram from a `LocalizedAlert`.

  Most of the logic is focused on fitting content into at most 14 slots by omitting stops from the Closure, the Gap, and/or the
  Ends as necessary.

  The logic reflects the flowchart created by Betsy and viewable [here](https://miro.com/app/board/uXjVP2Hgi18=/).

  # 📕 Terminology

  | Term | Definition |
  | :- | :- |
  | Slot | A single, labeled "point" on the diagram. Can be a stop, an omitted segment, a terminal stop, or a destination arrow. Slots do not necessarily correspond 1:1 with stops. |
  | Region | A group of slots forming one part of the diagram. Regions can overlap or subsume one another, with a consistent order of precedence: Closure > Gap > Current Location > Ends. |
  | Closure | The region containing disrupted stops. For station closures, the non-disrupted stops on either end of the disrupted area are also included. |
  | Current Location | The region containing this screen's home stop, as well as the stop(s) on either side of it. |
  | Gap | The region between the Closure and the screen's home stop. When present, the Gap always takes the Current Location stop closest to the Closure. |
  | Ends | The up-to 2 slots at either end of the diagram. These can take the form of either terminal stops, or destination arrows. |
  """

  alias Screens.V2.DisruptionDiagram, as: DD
  alias Screens.V2.DisruptionDiagram.Builder, as: B
  alias Screens.V2.DisruptionDiagram.Validator
  alias Screens.V2.LocalizedAlert

  import LocalizedAlert, only: [is_localized_alert: 1]

  # If the diagram is shorter than 6 slots, we "pad" it until it contains at least 6.
  @minimum_slot_count 6

  # If the closure is longer than 8 stops, it needs to be collapsed.
  @max_closure_count 8

  # When the closure needs to be collapsed, we omit stops
  # from it until the diagram contains 12 slots total.
  @max_count_with_collapsed_closure 12

  # When the closure needs to be collapsed, we automatically
  # also collapse the gap, making it take 2 slots or fewer.
  @max_collapsed_gap_count 2

  # If everything else fits, we still limit the gap to 3 slots or fewer.
  @max_gap_count 3

  @doc "Produces a JSON-serializable map representing the disruption diagram."
  @spec serialize(DD.t()) :: {:ok, DD.serialized_response()} | {:error, reason :: String.t()}
  def serialize(localized_alert) when is_localized_alert(localized_alert) do
    with :ok <- Validator.validate(localized_alert) do
      do_serialize(localized_alert)
    end
  rescue
    error ->
      error_string =
        Exception.message(error) <> "\n\n" <> Exception.format_stacktrace(__STACKTRACE__)

      {:error, "Exception raised during serialization:\n\n#{error_string}"}
  end

  defp do_serialize(localized_alert) do
    with {:ok, builder} <- B.new(localized_alert) do
      line = B.line(builder)

      serialize_by_line(line, builder)
    end
  end

  @spec serialize_by_line(DD.line(), B.t()) ::
          {:ok, DD.serialized_response()} | {:error, reason :: String.t()}
  # The Blue Line is the simplest case. We always show all stops, starting with Bowdoin.
  defp serialize_by_line(:blue, builder) do
    # The default stop sequence starts with Wonderland, so we need to put the stops in reverse order
    # to have Bowdoin appear first on the diagram.
    builder
    |> B.reverse()
    |> B.serialize()
    |> then(&{:ok, &1})
  end

  # For Mattapan Trolley, always show all stops, starting with Ashmont.
  defp serialize_by_line(:mattapan, builder) do
    builder
    |> B.serialize()
    |> then(&{:ok, &1})
  end

  # For the Green Line, we need to reverse the diagram in certain cases, as well as fit regions.
  defp serialize_by_line(:green, builder) do
    builder = maybe_reverse_gl(builder)

    with {:ok, builder} <- fit_regions(builder) do
      {:ok, B.serialize(builder)}
    end
  end

  # Red Line and Orange Line diagrams never need to be reversed--we just need to fit regions.
  defp serialize_by_line(_orange_or_red, builder) do
    with {:ok, builder} <- fit_regions(builder) do
      {:ok, B.serialize(builder)}
    end
  end

  # For GL, OL, and RL, it's possible for the stops we need to show in the diagram to span more than the maximum
  # number of slots (14). This function replaces segments of stops with single "omitted" slots in
  # order to keep the diagram small enough.
  #
  # In rare cases, the number of stops to show is too *small* and would look awkward, so we instead pad the diagram with
  # additional slots, pulling stops in from either side of the disrupted area.
  #
  # The fitting process stops after any one of the 3 functions in the `with` expression--`fit_closure_region`, `fit_gap_region`, or
  # `pad_slots`--makes a change to the diagram.
  defp fit_regions(builder) do
    with :unchanged <- fit_closure_region(builder),
         :unchanged <- fit_gap_region(builder),
         :unchanged <- pad_slots(builder) do
      {:ok, builder}
    else
      {:done, builder} -> {:ok, builder}
      {:error, _} = error_result -> error_result
    end
  end

  # The diagram needs to be flipped whenever it's not a GLX-only alert.
  defp maybe_reverse_gl(builder) do
    if B.glx_only?(builder) do
      builder
    else
      B.reverse(builder)
    end
  end

  defp fit_closure_region(builder) do
    current_closure_count = B.closure_count(builder)
    target_closure_count = @max_count_with_collapsed_closure - min_non_closure_slots(builder)

    if current_closure_count > @max_closure_count and target_closure_count < current_closure_count do
      with {:ok, builder} <- B.try_omit_stops(builder, :closure, target_closure_count) do
        {:done, minimize_gap(builder)}
      end
    else
      :unchanged
    end
  end

  defp minimize_gap(builder) do
    current_gap_count = B.gap_count(builder)
    target_gap_count = min_gap(builder)

    if target_gap_count < current_gap_count do
      # The gap never contains important stops, so `try_omit_stops` will always succeed.
      {:ok, builder} = B.try_omit_stops(builder, :gap, target_gap_count)
      builder
    else
      builder
    end
  end

  defp fit_gap_region(builder) do
    current_gap_count = B.gap_count(builder)
    closure_count = B.closure_count(builder)
    target_gap_slots = baseline_slots(closure_count) - non_gap_slots(builder)

    if current_gap_count >= @max_gap_count and target_gap_slots < current_gap_count do
      # The gap never contains important stops, so `try_omit_stops` will always succeed.
      {:ok, builder} = B.try_omit_stops(builder, :gap, target_gap_slots)

      {:done, builder}
    else
      :unchanged
    end
  end

  defp pad_slots(builder) do
    current_slot_count = B.slot_count(builder)

    if current_slot_count < @minimum_slot_count do
      {:done, B.add_slots(builder, @minimum_slot_count - current_slot_count)}
    else
      :unchanged
    end
  end

  defp min_non_closure_slots(builder) do
    B.end_count(builder) + B.current_location_count(builder) + min_gap(builder)
  end

  # Number of slots used by all regions except the gap, when it doesn't get minimized.
  defp non_gap_slots(builder) do
    B.end_count(builder) + B.closure_count(builder) + B.current_location_count(builder)
  end

  # The minimum possible size of the gap region.
  defp min_gap(builder) do
    min(B.gap_count(builder), @max_collapsed_gap_count)
  end

  for {closure, baseline} <- %{2 => 10, 3 => 10, 4 => 12, 5 => 12, 6 => 14, 7 => 14, 8 => 14} do
    defp baseline_slots(unquote(closure)), do: unquote(baseline)
  end

  # In rare cases when the home stop is inside the closure region,
  # more than 8 slots are available to the closure.
  defp baseline_slots(closure) when closure > 8, do: 14
end
