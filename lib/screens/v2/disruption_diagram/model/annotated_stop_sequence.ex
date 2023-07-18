defmodule Screens.V2.DisruptionDiagram.Model.AnnotatedStopSequence do
  alias Screens.V2.DisruptionDiagram.Model
  alias Screens.Routes.Route
  alias Screens.Stops.Stop

  @enforce_keys [:sequence, :metadata]
  defstruct @enforce_keys ++ [omitted_segments: []]

  @typedoc """
  An intermediate data structure for transforming a localized alert to a disruption diagram.

  Values should be accessed/manipulated only via public module functions.
  """
  @type t :: %__MODULE__{
          sequence: annotated_stop_sequence_array(),
          metadata: annotation_metadata(),
          omitted_segments: list(omitted_segment())
        }

  @type index :: non_neg_integer()

  @opaque annotated_stop_sequence_array :: %{
            index() => %{
              id: Stop.id(),
              label: Model.label_map(),
              home_stop?: boolean(),
              disrupted?: boolean(),
              terminal?: boolean()
            }
          }

  @opaque annotation_metadata :: %{
            line: Model.line_color(),
            length: non_neg_integer(),
            effect: :shuttle | :suspension | :station_closure,
            first_disrupted_stop: index(),
            last_disrupted_stop: index(),
            home_stop: index()
          }

  @opaque omitted_segment :: %{
            stop_index_range: Range.t(),
            label: Model.label()
          }

  @doc "Create a new AnnotatedStopSequence from a localized alert."
  @spec new(LocalizedAlert.t()) :: t()
  def new(localized_alert) do
    informed_stop_ids =
      for %{stop: "place-" <> _ = stop_id} <- localized_alert.alert.informed_entities do
        stop_id
      end
      |> MapSet.new()

    home_stop_id = localized_alert.location_context.home_stop

    stop_id_to_name =
      localized_alert.alert.informed_entities
      |> Enum.find_value(fn
        %{route: route_id} when is_binary(route_id) -> route_id
        _ -> false
      end)
      |> Stop.stop_id_to_name()

    stop_sequence =
      localized_alert.location_context.stop_sequences
      |> Enum.find(fn sequence ->
        MapSet.subset?(informed_stop_ids, MapSet.new(sequence))
      end)
      |> Enum.map(fn stop_id -> {stop_id, Map.fetch!(stop_id_to_name, stop_id)} end)

    stop_sequence_length = length(stop_sequence)

    builder = %{
      sequence: %{},
      metadata: %{
        line: get_line(localized_alert),
        length: stop_sequence_length,
        effect: localized_alert.alert.effect
      }
    }

    stop_sequence
    |> Enum.with_index()
    |> Enum.reduce(builder, fn {{stop_id, labels}, i}, builder_acc ->
      builder_acc =
        update_in(
          builder_acc.sequence,
          &Map.put(&1, i, %{
            id: stop_id,
            label: %{full: elem(labels, 0), abbrev: elem(labels, 1)},
            home_stop?: stop_id == home_stop_id,
            disrupted?: stop_id in informed_stop_ids,
            terminal?: i in [0, builder_acc.metadata.length - 1]
          })
        )

      builder_acc =
        update_in(builder_acc.metadata, fn meta ->
          disrupted_indexes =
            if builder_acc.sequence[i].disrupted?,
              do: [first_disrupted_stop: i, last_disrupted_stop: i],
              else: []

          home_stop_index = if builder_acc.sequence[i].home_stop?, do: [home_stop: i], else: []

          new_entries = Map.new(disrupted_indexes ++ home_stop_index)

          Map.merge(meta, new_entries, fn
            :first_disrupted_stop, prev_value, _new_value -> prev_value
            _k, _prev_value, new_value -> new_value
          end)
        end)

      builder_acc
    end)
    |> then(fn built -> struct(__MODULE__, built) end)
  end

  @doc """
  Reverses the annotated stop sequence, so that the last stop comes first and vice versa.

  This is helpful for cases where the disruption diagram lists stops in the opposite order of
  the direction_id=0 route order, e.g. on the Blue Line where we show Bowdoin first but
  direction_id=0 has Wonderland listed first.
  """
  @spec reverse_stops(t()) :: t()
  def reverse_stops(%__MODULE__{} = annotated_sequence) do
    stops_length = annotated_sequence.metadata.length

    flip_index = fn i -> stops_length - (i + 1) end

    # Reverse the sequence itself...
    sequence =
      Map.new(annotated_sequence.sequence, fn {i, stop_data} -> {flip_index.(i), stop_data} end)

    # ...and update the index values in `metadata` accordingly.
    metadata_updater =
      Map.new(
        [:first_disrupted_stop, :last_disrupted_stop, :home_stop],
        &{&1, flip_index.(annotated_sequence.metadata[&1])}
      )

    metadata = Map.merge(annotated_sequence.metadata, metadata_updater)

    %__MODULE__{sequence: sequence, metadata: metadata}
  end

  @doc """
  Stages the omission of stops from the given region, replacing them with a labeled placeholder.
  `target_closure_slots` gives the desired number of remaining slots after omission.
  Stops are omitted from the center of the region.

  The `label_callback` argument should be a function. The IDs of the stops omitted from the region will be passed to this
  function, which should return the appropriate label for those omitted stops.

  Omissions must be applied later, all at once, using `apply_omissions/1` (<- TODO is this accurate?).
  """
  @spec stage_omission(
          t(),
          :closure | :gap,
          pos_integer(),
          (MapSet.t(Stop.id()) -> Model.label())
        ) :: t()
  def stage_omission(annotated_sequence, region, target_closure_slots, label_callback)

  def stage_omission(
        %__MODULE__{} = annotated_sequence,
        :closure,
        target_closure_slots,
        label_callback
      ) do
    # TODO: Fix this logic, need to come at it from the other direction (take slice of stops to omit, not slices of stops to keep)
    #       Need to do the extra odd-number logic when target_closure_slots is EVEN, because the omitted chunk takes up one slot.

    # current_closure = closure_indices(annotated_sequence)
    # # If the number to remove is odd, l + r = num_to_omit - 1, so we need to increment one side of the to_remove tuple.
    # l = r = div(num_to_omit, 2)

    # to_remove =
    #   cond do
    #     # num_to_omit is even. We already have the correct number to remove from each side
    #     rem(num_to_omit, 2) == 0 -> {l, r}

    #     # num_to_omit is odd. Remove more from the side opposite the home stop.
    #     annotated_sequence.metadata.home_stop > annotated_sequence.metadata.last_disrupted_stop -> {l, r + 1}
    #     true -> {l + 1, r}
    #   end

    # update_in(annotated_sequence.omitted_segments, fn prev_omitted ->
    #   [%{stop_index_range: to_remove, label: label} | prev_omitted]
    # end)
  end

  def stage_omission(%__MODULE__{} = _annotated_sequence, :gap, _num_to_omit, _label_callback) do
    raise "Not yet implemented"
  end

  @doc "Serializes the sequence to a list of slots."
  @spec to_slots(t()) :: list(Model.slot())
  def to_slots(%__MODULE__{} = annotated_sequence) do
    annotated_sequence.sequence
    |> Enum.sort_by(fn {index, _stop_data} -> index end)
    |> Enum.map(fn
      {_index, stop_data} when stop_data.terminal? -> %{type: :terminal, label_id: stop_data.id}
      {_index, stop_data} -> %{label: stop_data.label, show_symbol: true}
    end)
  end

  @doc """
  Returns a sorted list of indices of the stops that are in the alert's informed entities.

  For station closures, this is the stops that are bypassed.

  For shuttles and suspensions, this is the stops that don't have any train service
  *as well as* the stops at the boundary of the disruption that don't have train service in one direction.
  """
  @spec disrupted_stop_indices(t()) :: list(index())
  def disrupted_stop_indices(%__MODULE__{} = annotated_sequence) do
    annotated_sequence.sequence
    |> Map.filter(fn {_i, stop_data} -> stop_data.disrupted? end)
    |> Map.keys()
    |> Enum.sort()
  end

  @doc """
  Returns the number of stops comprising the closure region of the diagram.

  **This can be different from the number of disrupted stops!**

  For station closures, we count from the stop on the left of the first bypassed stop to the stop on the right of the last bypassed stop:
      O === O === X === O === X === X === O === O
            |-----------------------------|
                       count = 6

  For shuttles and suspensions, it's just the stops that are directly informed by the alert:
      O === O === X - - X - - X - - X === O === O
                  |-----------------|
                       count = 4
  """
  @spec closure_count(t()) :: non_neg_integer()
  def closure_count(%__MODULE__{} = annotated_sequence) do
    annotated_sequence
    |> closure_indices()
    |> Enum.count()
  end

  # The closure has highest priority, so no other overlapping region can take stops from it.
  defp closure_indices(annotated_sequence), do: closure_ideal_indices(annotated_sequence)

  defp closure_ideal_indices(%{metadata: %{effect: :station_closure} = metadata}) do
    # first = One stop before the first bypassed stop, if it exists. Otherwise, the first bypassed stop.
    first = clamp(metadata.first_disrupted_stop - 1, metadata)

    # last = One stop past the last bypassed stop, if it exists. Otherwise, the last bypassed stop.
    last = clamp(metadata.last_disrupted_stop + 1, metadata)

    first..last//1
  end

  defp closure_ideal_indices(%{metadata: %{effect: continuous} = metadata})
       when continuous in [:shuttle, :suspension] do
    metadata.first_disrupted_stop..metadata.last_disrupted_stop//1
  end

  @doc """
  Returns the number of stops comprising the gap region of the diagram.

  This is always the stops between the closure region and the home stop.
  """
  @spec gap_count(t()) :: non_neg_integer()
  def gap_count(%__MODULE__{} = annotated_sequence) do
    Enum.count(gap_indices(annotated_sequence))
  end

  # The max number of stops allowed in the gap when it needs to be collapsed
  @collapsed_gap_max 2

  @doc """
  Returns the minimum possible size of the gap region.
  """
  @spec min_gap(t()) :: non_neg_integer()
  def min_gap(%__MODULE__{} = annotated_sequence) do
    min(gap_count(annotated_sequence), @collapsed_gap_max)
  end

  # The gap region has second highest priority and by its definition doesn't overlap with the closure region.
  defp gap_indices(annotated_sequence), do: gap_ideal_indices(annotated_sequence)

  defp gap_ideal_indices(annotated_sequence) do
    home_stop = annotated_sequence.metadata.home_stop

    closure_left..closure_right = closure_ideal_indices(annotated_sequence)

    cond do
      home_stop < closure_left -> (home_stop + 1)..(closure_left - 1)//1
      home_stop > closure_right -> (closure_right + 1)..(home_stop - 1)//1
      true -> ..
    end
  end

  @doc """
  Returns the number of stops comprising the ends of the diagram.

  This is normally 2, unless the closure region overlaps with one end.
  """
  @spec end_count(t()) :: non_neg_integer()
  def end_count(%__MODULE__{} = annotated_sequence) do
    annotated_sequence
    |> end_indices()
    |> Enum.count()
  end

  # Parts of the end region can be subsumed by the closure region.
  defp end_indices(annotated_sequence) do
    end_region = MapSet.new(end_ideal_indices(annotated_sequence))

    closure_region = MapSet.new(closure_ideal_indices(annotated_sequence))

    MapSet.difference(end_region, closure_region)
  end

  defp end_ideal_indices(annotated_sequence) do
    [0, annotated_sequence.metadata.length - 1]
  end

  @doc """
  Returns the number of stops comprising the "current location" region
  of the diagram.

  This is normally 2: the actual home stop, and its adjacent stop
  on the far side of the closure. Its adjacent stop on the near side is
  part of the gap.

  The number is lower when another region overlaps with this region.
  """
  @spec current_location_count(t()) :: non_neg_integer()
  def current_location_count(%__MODULE__{} = annotated_sequence) do
    annotated_sequence
    |> current_location_indices()
    |> Enum.count()
    |> tap(fn count ->
      # TODO: DEBUG ASSERTION! ADD UNIT TESTS & REMOVE THIS LIVE CODE BEFORE MERGING
      # At least one stop should always be removed from the indices returned by current_location_indices
      true = count in 0..2
    end)
  end

  # The current location region has lowest priority, can be subsumed by any other region.
  defp current_location_indices(annotated_sequence) do
    current_location_region = MapSet.new(current_location_ideal_indices(annotated_sequence))

    gap_region = MapSet.new(gap_ideal_indices(annotated_sequence))
    closure_region = MapSet.new(closure_ideal_indices(annotated_sequence))
    end_region = MapSet.new(end_ideal_indices(annotated_sequence))

    MapSet.difference(
      current_location_region,
      Enum.reduce([gap_region, closure_region, end_region], &MapSet.union/2)
    )
  end

  defp current_location_ideal_indices(%{metadata: metadata}) do
    home_stop = metadata.home_stop

    clamp(home_stop - 1, metadata)..clamp(home_stop + 1, metadata)//1
  end

  @spec effect(t()) :: :shuttle | :suspension | :station_closure
  def effect(%__MODULE__{} = annotated_sequence), do: annotated_sequence.metadata.effect

  @spec line(t()) :: Model.line_color()
  def line(%__MODULE__{} = annotated_sequence), do: annotated_sequence.metadata.line

  def current_station_index(%__MODULE__{} = annotated_sequence),
    do: annotated_sequence.metadata.home_stop

  defp get_line(localized_alert) do
    localized_alert.alert.informed_entities
    |> hd()
    |> Map.get(:route)
    |> Route.get_color_for_route()
  end

  # Adjusts an index to be within the bounds of the stop sequence.
  defp clamp(index, _metadata) when index < 0, do: 0
  defp clamp(index, metadata) when index >= metadata.length, do: metadata.length - 1
  defp clamp(index, _metadata), do: index
end
