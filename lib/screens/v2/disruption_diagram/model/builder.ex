defmodule Screens.V2.DisruptionDiagram.Model.Builder do
  @moduledoc """
  An intermediate data structure for transforming a localized alert to a disruption diagram.

  Values should be accessed/manipulated only via public module functions.
  """

  alias Screens.V2.DisruptionDiagram.Model
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Aja.Vector

  # Macros for using vectors in pattern matching/guards
  import Aja, only: [vec: 1, vec_size: 1, +++: 2]

  require Logger

  ##################
  # HELPER MODULES #
  ##################

  defmodule StopSlot do
    @moduledoc false

    @enforce_keys [:id, :label, :home_stop?, :disrupted?, :terminal?]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            id: Stop.id(),
            label: Model.label_map(),
            home_stop?: boolean(),
            disrupted?: boolean(),
            terminal?: boolean()
          }
  end

  defmodule OmittedSlot do
    @moduledoc false

    @enforce_keys [:label]
    defstruct @enforce_keys

    @type t :: %__MODULE__{label: Model.label()}
  end

  defmodule ArrowSlot do
    @moduledoc false

    @enforce_keys [:label_id]
    defstruct @enforce_keys

    @type t :: %__MODULE__{label_id: Model.end_label_id()}
  end

  ###############
  # MAIN MODULE #
  ###############

  @enforce_keys [:sequence]
  defstruct @enforce_keys ++ [metadata: nil, left_end: Vector.new(), right_end: Vector.new()]

  @type t :: %__MODULE__{
          sequence: sequence(),
          metadata: metadata(),
          left_end: end_sequence(),
          right_end: end_sequence()
        }

  # Starts out only containing StopSlots, but may contain other slot types
  # as we work our way toward building the final diagram output.
  @opaque sequence :: Vector.t(StopSlot.t() | OmittedSlot.t() | ArrowSlot.t())

  @opaque end_sequence :: Vector.t(StopSlot.t())

  @opaque metadata :: %{
            line: Model.line_color(),
            effect: :shuttle | :suspension | :station_closure,
            first_disrupted_stop: Vector.index(),
            last_disrupted_stop: Vector.index(),
            home_stop: Vector.index()
          }

  @doc "Creates a new Builder from a localized alert."
  @spec new(LocalizedAlert.t()) :: t()
  def new(localized_alert) do
    informed_stop_ids =
      for %{stop: "place-" <> _ = stop_id} <- localized_alert.alert.informed_entities do
        stop_id
      end
      |> MapSet.new()

    # TODO: Probably needs adjusting for GL. One disruption can inform multiple routes.
    # Need to select the route that completely contains all informed stops, rather than just the first one we find.
    # -> Change localized_alert.location_context.stop_sequences to a map keyed on route ID??
    informed_route_id =
      localized_alert.alert.informed_entities
      |> Enum.find_value(fn
        %{route: "Green" <> _ = route_id} -> route_id
        %{route: route_id} when route_id in ["Blue", "Orange", "Red"] -> route_id
        _ -> false
      end)

    stop_id_to_name = Stop.stop_id_to_name(informed_route_id)

    stop_sequence =
      localized_alert.location_context.stop_sequences
      |> Enum.find(fn sequence ->
        MapSet.subset?(informed_stop_ids, MapSet.new(sequence))
      end)
      |> Enum.map(fn stop_id -> {stop_id, Map.fetch!(stop_id_to_name, stop_id)} end)

    home_stop_id = localized_alert.location_context.home_stop

    sequence =
      stop_sequence
      |> Vector.new(fn {stop_id, labels} ->
        %StopSlot{
          id: stop_id,
          label: %{full: elem(labels, 0), abbrev: elem(labels, 1)},
          home_stop?: stop_id == home_stop_id,
          disrupted?: stop_id in informed_stop_ids,
          # We'll set this value just below, after the whole sequence is built.
          terminal?: false
        }
      end)
      |> Vector.update_at!(0, &%{&1 | terminal?: true})
      |> Vector.update_at!(-1, &%{&1 | terminal?: true})

    init_metadata = %{
      line: Route.get_color_for_route(informed_route_id),
      effect: localized_alert.alert.effect
    }

    %__MODULE__{sequence: sequence, metadata: init_metadata}
    |> recalculate_metadata()
    |> split_end_stops()
  end

  # Since we always show all stops for the Blue Line, we don't need to do
  # anything special with the ends. They don't need to be split out.
  defp split_end_stops(builder) when builder.metadata.line == :blue, do: builder

  defp split_end_stops(builder) do
    in_diagram =
      [
        closure_ideal_indices(builder),
        gap_ideal_indices(builder),
        current_location_ideal_indices(builder)
      ]
      |> Enum.map(&MapSet.new/1)
      |> Enum.reduce(&MapSet.union/2)

    {leftmost_stop_index, rightmost_stop_index} = Enum.min_max(in_diagram)

    # Example: If the first one we're keeping is at index 5,
    # then it's the 6th element so we need to slice off the first 5.
    left_slice_amount = leftmost_stop_index

    last_index = Vector.size(builder.sequence) - 1
    right_slice_amount = last_index - rightmost_stop_index

    builder
    |> split_right_end(right_slice_amount)
    |> split_left_end(left_slice_amount)
    |> recalculate_metadata()
  end

  defp split_left_end(builder, 0), do: %{builder | left_end: Vector.new()}

  defp split_left_end(builder, amount) do
    {left_end, sequence} = Vector.split(builder.sequence, amount)

    # (We expect recalculate_metadata to be invoked in the calling function, so don't do it here.)
    %{builder | sequence: sequence, left_end: left_end}
  end

  defp split_right_end(builder, 0), do: %{builder | right_end: Vector.new()}

  defp split_right_end(builder, amount) do
    {sequence, right_end} = Vector.split(builder.sequence, -amount)

    %{builder | sequence: sequence, right_end: right_end}
  end

  # Must be called after any operation that causes element indices to change in builder.sequence.
  # That is, when one or more elements are moved, inserted, or removed anywhere before the end of the vector.
  defp recalculate_metadata(builder) do
    # We're going to replace all of the indices, so throw out the old ones.
    # That way, if we fail to set one of them (which shouldn't happen),
    # later code will fail instead of continuing with inaccurate data.
    meta_without_indices = Map.take(builder.metadata, [:line, :effect])

    builder.sequence
    |> Vector.with_index()
    # Note to reviewer: foldl, "fold from left", is a synonym of reduce
    # (TODO: Remove this comment)
    |> Vector.foldl(meta_without_indices, fn
      {%StopSlot{} = stop_data, i}, meta ->
        disrupted_indices =
          if stop_data.disrupted?,
            do: [first_disrupted_stop: i, last_disrupted_stop: i],
            else: []

        home_stop_index = if stop_data.home_stop?, do: [home_stop: i], else: []

        new_entries = Map.new(disrupted_indices ++ home_stop_index)

        Map.merge(meta, new_entries, fn
          # This lets us set first_disrupted_stop only once.
          :first_disrupted_stop, prev_value, _new_value -> prev_value
          # The other entries get updated whenever there's a new value.
          _k, _prev_value, new_value -> new_value
        end)

      {_other_slot, _index}, meta ->
        meta
    end)
    |> then(&put_in(builder.metadata, &1))
  end

  @doc """
  Reverses the builder's internal stop sequence, so that the last stop comes first and vice versa.

  This is helpful for cases where the disruption diagram lists stops in the opposite order of
  the direction_id=0 route order, e.g. in Blue Line diagrams where we show Bowdoin first but
  direction_id=0 has Wonderland listed first.
  """
  @spec reverse_stops(t()) :: t()
  def reverse_stops(%__MODULE__{} = builder) do
    %{
      builder
      | sequence: Vector.reverse(builder.sequence),
        # The ends swap places, and also have their elements flipped.
        left_end: Vector.reverse(builder.right_end),
        right_end: Vector.reverse(builder.left_end)
    }
    |> recalculate_metadata()
  end

  @doc """
  Omits stops from the given region, replacing them with a labeled "blank" slot.
  `target_slots` gives the desired number of remaining slots after omission.
  Stops are omitted from the center of the region.

  The `label_callback` argument should be a function. The IDs of the omitted stops will be passed to this
  function, which should return the appropriate label for those omitted stops.
  """
  @spec omit_stops(
          t(),
          :closure | :gap,
          pos_integer(),
          (MapSet.t(Stop.id()) -> Model.label())
        ) :: t()
  def omit_stops(builder, region, target_slots, label_callback)

  def omit_stops(
        %__MODULE__{} = builder,
        :closure,
        target_closure_slots,
        label_callback
      ) do
    do_omit(builder, closure_indices(builder), target_closure_slots, label_callback)
  end

  def omit_stops(%__MODULE__{} = builder, :gap, target_gap_stops, label_callback) do
    do_omit(builder, gap_indices(builder), target_gap_stops, label_callback)
  end

  defp do_omit(builder, current_region_indices, target_slots, label_callback) do
    region_length = Enum.count(current_region_indices)

    if target_slots < region_length do
      raise "Nothing to omit, function should not have been called"
    end

    # We need to omit 1 more stop than the difference, to account for the omission itself, which still takes up one slot:
    #
    # region: X - - X - - X - - X - - X :: length 5
    # target_slots: 3
    #
    # 5 - 3 + 1 = 3 stops to omit (not 2!)
    #
    # after omission: X - - ... - - X :: length 3
    num_to_omit = region_length - target_slots + 1

    num_to_keep = region_length - num_to_omit

    # (Just left of center if region_length is even.)
    center_index = Enum.at(current_region_indices, div(region_length - 1, 2))

    home_stop_is_right_of_center = builder.metadata.home_stop > center_index

    # If the number of slots to keep is odd, more slots are devoted to the side of the region nearest the home stop.
    offset =
      cond do
        # num_to_keep is odd and the home stop is NOT to the right of the closure center.
        rem(num_to_keep, 2) == 1 and not home_stop_is_right_of_center -> div(num_to_keep, 2) + 1
        # num_to_keep is even, OR num_to_keep is odd and the home stop is to the right of the closure center.
        true -> div(num_to_keep, 2)
      end

    omitted_indices =
      current_region_indices
      |> Enum.drop(offset)
      |> Enum.take(num_to_omit)

    if omitted_indices == [] do
      builder
    else
      label =
        omitted_indices
        |> MapSet.new(&builder.sequence[&1].id)
        |> label_callback.()

      {first_omitted, last_omitted} = Enum.min_max(omitted_indices)

      builder
      |> update_in([Access.key(:sequence)], fn seq ->
        seq
        # Start with the part left of the omitted section
        |> Vector.slice(0..(first_omitted - 1)//1)
        # Add the new omitted slot
        |> Vector.append(%OmittedSlot{label: label})
        # Add the part right of the omitted section
        |> Vector.concat(Vector.slice(seq, (last_omitted + 1)..vec_size(seq)//1))
      end)
      |> recalculate_metadata()
    end
  end

  @doc """
  Moves `num_to_add` stops back from the left/right end groups to the main sequence,
  effectively "padding" the diagram with more stops that otherwise would have been
  omitted inside one of the destination-arrow slots.
  Stops are added from the end closest to the home stop, unless it's empty.
  In that case, they are added from the opposite end.
  """
  @spec add_slots(t(), pos_integer()) :: t()
  def add_slots(%__MODULE__{} = builder, num_to_add) do
    closure_region_indices = closure_indices(builder)
    region_length = Enum.count(closure_region_indices)

    center_index = Enum.at(closure_region_indices, div(region_length - 1, 2))

    home_stop_is_right_of_center = builder.metadata.home_stop > center_index

    pull_from = if home_stop_is_right_of_center, do: :right_end, else: :left_end

    builder
    |> do_add_slots(num_to_add, pull_from)
    |> recalculate_metadata()
  end

  defp do_add_slots(builder, 0, _), do: builder

  defp do_add_slots(builder, _greater_than_0, _)
       when vec_size(builder.left_end) == 0 and vec_size(builder.right_end) == 0 do
    Logger.warn("[disruption diagram no more end stops available]")
    builder
  end

  defp do_add_slots(builder, num_to_add, :left_end)
       when vec_size(builder.left_end) == 0 do
    do_add_slots(builder, num_to_add, :right_end)
  end

  defp do_add_slots(builder, num_to_add, :right_end)
       when vec_size(builder.right_end) == 0 do
    do_add_slots(builder, num_to_add, :left_end)
  end

  defp do_add_slots(builder, num_to_add, :right_end) do
    {stop_data, new_right_end} = Vector.pop_at(builder.right_end, 0)

    builder
    |> put_in([Access.key(:right_end)], new_right_end)
    |> update_in([Access.key(:sequence)], &Vector.append(&1, stop_data))
    |> do_add_slots(num_to_add - 1, :right_end)
  end

  defp do_add_slots(builder, num_to_add, :left_end) do
    {stop_data, new_left_end} = Vector.pop_last!(builder.left_end)

    builder
    |> put_in([Access.key(:left_end)], new_left_end)
    |> update_in([Access.key(:sequence)], &Vector.prepend(&1, stop_data))
    |> do_add_slots(num_to_add - 1, :left_end)
  end

  @doc "Serializes the builder to a list of Model.slot()'s."
  @spec to_slots(t()) :: list(Model.slot())
  def to_slots(%__MODULE__{} = builder) do
    final_sequence = add_back_end_slots(builder)

    Aja.Enum.map(final_sequence, fn
      %ArrowSlot{} = arrow -> %{type: :arrow, label_id: arrow.label_id}
      %StopSlot{} = stop when stop.terminal? -> %{type: :terminal, label_id: stop.id}
      %StopSlot{} = stop -> %{label: stop.label, show_symbol: true}
      %OmittedSlot{} = omitted -> %{label: omitted.label, show_symbol: false}
    end)
  end

  # Re-adds each of left_end and right_end to the main sequence as either:
  # - a terminal stop slot if the end contains 1 stop,
  # - a destination-arrow slot if the end contains multiple stops, or
  # - nothing if the end contains no stops.
  #
  # Returns a Vector, not a Builder.
  defp add_back_end_slots(builder) do
    left_end = get_end_slot(builder.metadata.line, builder.left_end)
    right_end = get_end_slot(builder.metadata.line, builder.right_end)

    left_end +++ builder.sequence +++ right_end
  end

  defp get_end_slot(_line, vec([])), do: Vector.new()

  defp get_end_slot(_line, vec([%{terminal?: true} = stop_data])), do: Vector.new([stop_data])

  defp get_end_slot(line, stops) do
    stop_ids = Aja.Enum.map(stops, & &1.id)

    label_id = Model.get_end_label_id(line, stop_ids)

    Vector.new([%ArrowSlot{label_id: label_id}])
  end

  @doc """
  Returns the number of slots that would be in the diagram produced by the current builder.
  """
  @spec slot_count(t()) :: non_neg_integer()
  def slot_count(%__MODULE__{} = builder) do
    left_end_slot_count = min(vec_size(builder.left_end), 1)
    right_end_slot_count = min(vec_size(builder.right_end), 1)

    vec_size(builder.sequence) + left_end_slot_count + right_end_slot_count
  end

  @doc """
  Returns a sorted list of indices of the stops that are in the alert's informed entities.
  For station closures, this is the stops that are bypassed.
  For shuttles and suspensions, this is the stops that don't have any train service
  *as well as* the stops at the boundary of the disruption that don't have train service in one direction.
  """
  @spec disrupted_stop_indices(t()) :: list(Vector.index())
  def disrupted_stop_indices(%__MODULE__{} = builder) do
    builder.sequence
    |> Vector.with_index()
    |> Vector.filter(fn
      {%StopSlot{} = stop_data, _i} -> stop_data.disrupted?
      {_other_slot_type, _i} -> false
    end)
    |> Aja.Enum.map(fn {_stop_data, i} -> i end)
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
  def closure_count(%__MODULE__{} = builder) do
    builder
    |> closure_indices()
    |> Enum.count()
  end

  # The closure has highest priority, so no other overlapping region can take stops from it.
  defp closure_indices(builder), do: closure_ideal_indices(builder)

  defp closure_ideal_indices(%{metadata: %{effect: :station_closure}} = builder) do
    # first = One stop before the first bypassed stop, if it exists. Otherwise, the first bypassed stop.
    first = clamp(builder.metadata.first_disrupted_stop - 1, vec_size(builder.sequence))

    # last = One stop past the last bypassed stop, if it exists. Otherwise, the last bypassed stop.
    last = clamp(builder.metadata.last_disrupted_stop + 1, vec_size(builder.sequence))

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
  def gap_count(%__MODULE__{} = builder) do
    Enum.count(gap_indices(builder))
  end

  # The max number of stops allowed in the gap when it needs to be collapsed
  @collapsed_gap_max 2

  @doc """
  Returns the minimum possible size of the gap region.
  """
  @spec min_gap(t()) :: non_neg_integer()
  def min_gap(%__MODULE__{} = builder) do
    min(gap_count(builder), @collapsed_gap_max)
  end

  # The gap region has second highest priority and by its definition doesn't overlap with the closure region.
  defp gap_indices(builder), do: gap_ideal_indices(builder)

  defp gap_ideal_indices(builder) do
    home_stop = builder.metadata.home_stop
    closure_left..closure_right = closure_ideal_indices(builder)

    cond do
      home_stop < closure_left -> (home_stop + 1)..(closure_left - 1)//1
      home_stop > closure_right -> (closure_right + 1)..(home_stop - 1)//1
      true -> ..
    end
  end

  @doc """
  Returns the number of stops comprising the "current location" region
  of the diagram.

  This is normally 2: the actual home stop, and its adjacent stop
  on the far side of the closure. Its adjacent stop on the near side is
  part of the gap.

  The number is lower when the closure region overlaps with this region,
  or when the home stop is a terminal.

  If the home stop is inside the closure: 0
  If the home stop is on the boundary of the closure and not at a terminal: 1
  If the home stop is on the boundary of the closure and at a terminal: 0
  If the home stop is outside the closure and not at a terminal: 2
  If the home stop is outside the closure and at a terminal: 1
  """
  @spec current_location_count(t()) :: non_neg_integer()
  def current_location_count(%__MODULE__{} = builder) do
    builder
    |> current_location_indices()
    |> Enum.count()
    |> tap(fn count ->
      # TODO: DEBUG ASSERTION! ADD UNIT TESTS & REMOVE THIS LIVE CODE BEFORE MERGING
      # At least one stop should always be removed from the indices returned by current_location_indices
      true = count in 0..2
    end)
  end

  # The current location region can be subsumed by the closure and the gap regions.
  defp current_location_indices(builder) do
    current_location_region = MapSet.new(current_location_ideal_indices(builder))

    gap_region = MapSet.new(gap_ideal_indices(builder))
    closure_region = MapSet.new(closure_ideal_indices(builder))

    MapSet.difference(
      current_location_region,
      MapSet.union(gap_region, closure_region)
    )
    |> Enum.min_max(fn -> .. end)
    |> case do
      {left, right} -> left..right//1
      empty_range -> empty_range
    end
  end

  defp current_location_ideal_indices(builder) do
    home_stop = builder.metadata.home_stop

    size = vec_size(builder.sequence)

    clamp(home_stop - 1, size)..clamp(home_stop + 1, size)//1
  end

  @doc """
  Returns the number of stops comprising the ends of the diagram.

  This is normally 2, unless another region contains either terminal stop of the line.
  """
  @spec end_count(t()) :: non_neg_integer()
  def end_count(%__MODULE__{} = builder) do
    # TODO: Determine without using indices
    builder
    |> end_indices()
    |> Enum.count()
  end

  # The end region has lowest precedence. Its two stops can be subsumed by any other region.
  defp end_indices(builder) do
    end_region = MapSet.new(end_ideal_indices(builder))

    c = MapSet.new(closure_ideal_indices(builder))
    g = MapSet.new(gap_ideal_indices(builder))
    cl = MapSet.new(current_location_ideal_indices(builder))

    MapSet.difference(end_region, Enum.reduce([c, g, cl], &MapSet.union/2))
  end

  defp end_ideal_indices(builder) do
    [0, vec_size(builder.sequence) - 1]
  end

  @spec effect(t()) :: :shuttle | :suspension | :station_closure
  def effect(%__MODULE__{} = builder), do: builder.metadata.effect

  @spec line(t()) :: Model.line_color()
  def line(%__MODULE__{} = builder), do: builder.metadata.line

  def current_station_index(%__MODULE__{} = builder),
    do: builder.metadata.home_stop

  # Adjusts an index to be within the bounds of the stop sequence.

  defp clamp(index, _sequence_size) when index < 0, do: 0
  defp clamp(index, sequence_size) when index >= sequence_size, do: sequence_size - 1
  defp clamp(index, _sequence_size), do: index

  def add_back_end_slots(builder) do
    left_end = get_end_slot(builder.metadata.line, builder.left_end)
    right_end = get_end_slot(builder.metadata.line, builder.right_end)

    builder =
      case Vector.first(left_end) do
        nil ->
          builder

        slot ->
          update_in(builder, [Access.key(:sequence)], fn seq ->
            Vector.prepend(seq, slot)
          end)
      end

    case Vector.last(right_end) do
      nil ->
        builder

      slot ->
        update_in(builder, [Access.key(:sequence)], fn seq -> Vector.append(seq, slot) end)
    end
  end
end
