defmodule Screens.V2.DisruptionDiagram.Model do
  @moduledoc """
  Functions to generate a disruption diagram from a `LocalizedAlert`.
  """

  alias Screens.V2.DisruptionDiagram, as: DD
  alias Screens.V2.DisruptionDiagram.Builder
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
    with {:ok, builder} <- Builder.new(localized_alert) do
      line = Builder.line(builder)

      {:ok, serialize_by_line(line, builder)}
    end
  end

  @spec serialize_by_line(DD.line_color(), Builder.t()) :: DD.serialized_response()
  # The Blue Line is the simplest case. We always show all stops, starting with Bowdoin.
  defp serialize_by_line(:blue, builder) do
    # The default stop sequence starts with Wonderland, so we need to put the stops in reverse order
    # to have Bowdoin appear first on the diagram.
    builder
    |> Builder.reverse()
    |> Builder.serialize()
  end

  # For the Green Line, we need to reverse the diagram in certain cases, as well as fit regions.
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
    if Builder.glx_only?(builder) do
      builder
    else
      Builder.reverse(builder)
    end
  end

  defp fit_closure_region(builder) do
    current_closure_count = Builder.closure_count(builder)
    target_closure_count = @max_count_with_collapsed_closure - min_non_closure_slots(builder)

    if current_closure_count > @max_closure_count and target_closure_count < current_closure_count do
      builder =
        builder
        |> Builder.omit_stops(:closure, target_closure_count)
        |> minimize_gap()

      {:done, builder}
    else
      :unchanged
    end
  end

  defp minimize_gap(builder) do
    current_gap_count = Builder.gap_count(builder)
    target_gap_count = min_gap(builder)

    if target_gap_count < current_gap_count do
      Builder.omit_stops(builder, :gap, target_gap_count)
    else
      builder
    end
  end

  defp fit_gap_region(builder) do
    current_gap_count = Builder.gap_count(builder)
    closure_count = Builder.closure_count(builder)
    target_gap_slots = baseline_slots(closure_count) - non_gap_slots(builder)

    if current_gap_count >= @max_gap_count and target_gap_slots < current_gap_count do
      builder = Builder.omit_stops(builder, :gap, target_gap_slots)

      {:done, builder}
    else
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
    min(Builder.gap_count(builder), @max_collapsed_gap_count)
  end

  for {closure, baseline} <- %{2 => 10, 3 => 10, 4 => 12, 5 => 12, 6 => 14, 7 => 14, 8 => 14} do
    defp baseline_slots(unquote(closure)), do: unquote(baseline)
  end
end

# TODO: Implement additional logic in Builder.omit_stops to avoid
#       omitting the home stop or bypasses stops.

# TODO: Original code at the start of Builder.new is hot garbo.
# Make it more resilient--should get stop/route stuff based on the route that fully contains
# informed stops ++ home stop (since really we only care about getting all the info we need to draw the diagram between them)
