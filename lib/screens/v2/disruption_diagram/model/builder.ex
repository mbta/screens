defmodule Screens.V2.DisruptionDiagram.Model.Builder do
  @moduledoc """
  An intermediate data structure for transforming a localized alert to a disruption diagram.

  Values should be accessed/manipulated only via public module functions.
  """

  alias Screens.V2.DisruptionDiagram.Model
  alias Screens.Routes.Route
  alias Screens.Stops.Stop

  require Logger

  # Lets the nested modules access things in this module without using fully qualified name
  alias __MODULE__

  @type index :: non_neg_integer()

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

    @enforce_keys [:omitted_slots, :label]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            omitted_slots: %{Builder.index() => StopSlot.t()},
            label: Model.label()
          }
  end

  defmodule ArrowSlot do
    @moduledoc false

    @enforce_keys [:label_id]
    defstruct @enforce_keys

    @type t :: %__MODULE__{label_id: Model.end_label_id()}
  end

  @enforce_keys [:sequence, :metadata, :left_omitted, :right_omitted]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          sequence: annotated_stop_sequence_array(),
          metadata: annotation_metadata(),
          left_omitted: annotated_stop_sequence_array(),
          right_omitted: annotated_stop_sequence_array()
        }

  @opaque annotated_stop_sequence_array :: %{
            index() => StopSlot.t() | OmittedSlot.t()
          }

  @opaque annotation_metadata :: %{
            line: Model.line_color(),
            length: non_neg_integer(),
            effect: :shuttle | :suspension | :station_closure,
            first_disrupted_stop: index(),
            last_disrupted_stop: index(),
            home_stop: index()
          }

  @doc "Creates a new Builder from a localized alert."
  @spec new(LocalizedAlert.t()) :: t()
  def new(localized_alert) do
    home_stop_id = localized_alert.location_context.home_stop

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

    stop_sequence_length = length(stop_sequence)

    init_builder = %{
      sequence: %{},
      metadata: %{
        line: Route.get_color_for_route(informed_route_id),
        length: stop_sequence_length,
        effect: localized_alert.alert.effect
      },
      left_omitted: %{},
      right_omitted: %{}
    }

    stop_sequence
    |> Enum.with_index()
    |> Enum.reduce(init_builder, &add_stop(&1, &2, home_stop_id, informed_stop_ids))
    |> then(fn builder -> struct!(__MODULE__, builder) end)
    |> omit_end_stops()
  end

  defp add_stop({{stop_id, labels}, i}, init_builder, home_stop_id, informed_stop_ids) do
    is_disrupted = stop_id in informed_stop_ids
    is_home_stop = stop_id == home_stop_id

    init_builder
    |> update_in(
      [:sequence],
      &Map.put(&1, i, %StopSlot{
        id: stop_id,
        label: %{full: elem(labels, 0), abbrev: elem(labels, 1)},
        home_stop?: is_home_stop,
        disrupted?: is_disrupted,
        terminal?: i in [0, init_builder.metadata.length - 1]
      })
    )
    |> update_in([:metadata], fn meta ->
      disrupted_indexes =
        if is_disrupted,
          do: [first_disrupted_stop: i, last_disrupted_stop: i],
          else: []

      home_stop_index = if is_home_stop, do: [home_stop: i], else: []

      new_entries = Map.new(disrupted_indexes ++ home_stop_index)

      Map.merge(meta, new_entries, fn
        :first_disrupted_stop, prev_value, _new_value -> prev_value
        _k, _prev_value, new_value -> new_value
      end)
    end)
  end

  # No end stops need to be omitted for Blue Line diagrams.
  defp omit_end_stops(builder) when builder.metadata.line == :blue, do: builder

  defp omit_end_stops(builder) do
    in_diagram =
      [
        closure_ideal_indices(builder),
        gap_ideal_indices(builder),
        current_location_ideal_indices(builder)
      ]
      |> Enum.map(&MapSet.new/1)
      |> Enum.reduce(&MapSet.union/2)

    {leftmost_stop_index, rightmost_stop_index} = Enum.min_max(in_diagram)

    left_omitted = Map.take(builder.sequence, Enum.to_list(0..(leftmost_stop_index - 1)//1))

    right_omitted =
      Map.take(
        builder.sequence,
        Enum.to_list((rightmost_stop_index + 1)..(builder.metadata.length - 1)//1)
      )

    builder = %{builder | left_omitted: left_omitted, right_omitted: right_omitted}

    keys_to_remove = Map.keys(left_omitted) ++ Map.keys(right_omitted)

    remove_stops(builder, keys_to_remove)

    # Re-adding to the main sequence for serialization:
    # - if map size is 0, return []
    # - if map size is 1, return [%StopSlot{}]. Main serialize function will transform it to a terminal end_slot map
    # - if map size > 1, determine label using ✨magic✨ and return [%DestinationSlot{}]
    # serialized result gets ++'ed onto main list.
    # - *** MUST INCREMENT ARRAY INDICES IF LEFT SIDE ISN'T EMPTY! ***
    #   - Is there a way to avoid this or do things more elegantly?
  end

  @doc """
  Reverses the builder's internal stop sequence, so that the last stop comes first and vice versa.

  This is helpful for cases where the disruption diagram lists stops in the opposite order of
  the direction_id=0 route order, e.g. in Blue Line diagrams where we show Bowdoin first but
  direction_id=0 has Wonderland listed first.
  """
  @spec reverse_stops(t()) :: t()
  def reverse_stops(%__MODULE__{} = builder) do
    stops_length = builder.metadata.length

    flip_index = fn i -> stops_length - (i + 1) end

    builder
    # Reverse the sequence itself...
    |> update_in([Access.key(:sequence)], fn seq ->
      Map.new(seq, fn {i, stop_data} -> {flip_index.(i), stop_data} end)
    end)
    # ...and update the index values in `metadata` accordingly.
    |> update_in(
      [Access.key(:metadata)],
      &%{
        &1
        | first_disrupted_stop: flip_index.(&1.first_disrupted_stop),
          last_disrupted_stop: flip_index.(&1.last_disrupted_stop),
          home_stop: flip_index.(&1.home_stop)
      }
    )
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
      )
      when target_closure_slots >= 3 do
    do_omit(builder, closure_indices(builder), target_closure_slots, label_callback)
  end

  def omit_stops(%__MODULE__{} = builder, :gap, target_gap_stops, label_callback)
      when target_gap_stops <= 5 do
    do_omit(builder, gap_indices(builder), target_gap_stops, label_callback)
  end

  # More than 5 target_gap_slots means we don't need to omit? This works but not sure why yet.
  def omit_stops(%__MODULE__{} = builder, :gap, _target_gap_stops, _label_callback), do: builder

  # TODO what even do we name this function
  defp do_omit(builder, current_region_indices, target_slots, label_callback) do
    region_length = Enum.count(current_region_indices)

    # We need to omit 1 more stop than the difference, to account for the omission itself, which still takes up one slot:
    #
    # region: X - - X - - X - - X - - X :: length 5
    # target_slots: 3
    #
    # 5 - 3 + 1 = 3 stops to omit (not 2!)
    #
    # after omission: X - - _ - - X :: length 3
    num_to_omit = region_length - target_slots + 1

    num_to_keep = region_length - num_to_omit

    center_index = Enum.at(current_region_indices, div(region_length, 2))

    home_stop_is_right_of_center = builder.metadata.home_stop > center_index

    # If the number of slots to keep is odd, more slots are devoted to the side of the region nearest the home stop.
    offset =
      cond do
        # num_to_keep is even, OR num_to_keep is odd and the home stop is to the right of the closure center.
        rem(num_to_keep, 2) == 0 or home_stop_is_right_of_center -> div(num_to_keep, 2)
        # num_to_keep is odd and the home stop is NOT to the right of the closure center.
        true -> div(num_to_keep, 2) + 1
      end

    omitted_indices =
      current_region_indices
      |> Enum.drop(offset)
      |> Enum.take(num_to_omit)

    label =
      omitted_indices
      |> MapSet.new(&builder.sequence[&1].id)
      |> label_callback.()

    apply_omission(builder, omitted_indices, label)
  end

  # TODO: Do we need to hold onto the omitted StopSlots? Can we just toss them?
  defp apply_omission(builder, omitted_indices, label) do
    {first_omitted, last_omitted} = Enum.min_max(omitted_indices)

    left_shift_amount = last_omitted - first_omitted

    update_index = fn
      i when i > last_omitted -> i - left_shift_amount
      i -> i
    end

    builder =
      update_in(builder.sequence, fn seq ->
        # Remove keys
        {omitted_slots, seq} = Map.split(seq, omitted_indices)

        seq
        # Insert omitted slot
        |> Map.put(first_omitted, %OmittedSlot{omitted_slots: omitted_slots, label: label})
        # Update indices
        |> Map.new(fn {index, stop_data} -> {update_index.(index), stop_data} end)
      end)

    # Update indices in builder.metadata
    update_in(
      builder.metadata,
      &%{
        &1
        | first_disrupted_stop: update_index.(&1.first_disrupted_stop),
          last_disrupted_stop: update_index.(&1.last_disrupted_stop),
          home_stop: update_index.(&1.home_stop),
          length: map_size(builder.sequence)
      }
    )
  end

  def add_slots(%__MODULE__{} = builder, num_to_add) do
    closure_region_indices = closure_indices(builder)
    region_length = Enum.count(closure_region_indices)

    center_index = Enum.at(closure_region_indices, div(region_length, 2))

    home_stop_is_right_of_center = builder.metadata.home_stop > center_index

    pull_from = if home_stop_is_right_of_center, do: :right_omitted, else: :left_omitted

    do_add_slots(builder, num_to_add, pull_from)
  end

  defp do_add_slots(builder, 0, _), do: builder

  defp do_add_slots(builder, _greater_than_0, _)
       when map_size(builder.left_omitted) == 0 and map_size(builder.right_omitted) == 0 do
    Logger.warn("[disruption diagram no more end stops available]")
    builder
  end

  defp do_add_slots(builder, num_to_add, :left_omitted)
       when map_size(builder.left_omitted) == 0 do
    do_add_slots(builder, num_to_add, :right_omitted)
  end

  defp do_add_slots(builder, num_to_add, :right_omitted)
       when map_size(builder.right_omitted) == 0 do
    do_add_slots(builder, num_to_add, :left_omitted)
  end

  defp do_add_slots(builder, num_to_add, :right_omitted) do
    {index, _} = Enum.min_by(builder.right_omitted, fn {index, _stop_data} -> index end)

    {stop_data, new_right_omitted} = Map.pop(builder.right_omitted, index)

    builder
    |> put_in([:right_omitted], new_right_omitted)
    |> insert_stop(map_size(builder.sequence), stop_data)
    |> do_add_slots(num_to_add - 1, :right_omitted)
  end

  defp do_add_slots(builder, num_to_add, :left_omitted) do
    {index, _} = Enum.max_by(builder.left_omitted, fn {index, _stop_data} -> index end)

    {stop_data, new_left_omitted} = Map.pop(builder.left_omitted, index)

    builder
    |> put_in([:left_omitted], new_left_omitted)
    |> insert_stop(0, stop_data)
    |> do_add_slots(num_to_add - 1, :left_omitted)
  end

  defp insert_stop(builder, at_index, stop) when at_index == map_size(builder) do
    builder
    |> update_in([:sequence], &Map.put(&1, at_index, stop))
    |> update_in([:metadata], &%{&1 | length: &1.length + 1})
  end

  defp insert_stop(builder, at_index, stop) do
    builder
    |> update_in([Access.key(:sequence)], fn seq ->
      seq
      |> Map.new(fn
        {index, stop_data} when index < at_index -> {index, stop_data}
        {index, stop_data} -> {index + 1, stop_data}
      end)
      |> Map.put(at_index, stop)
    end)
    |> update_in([Access.key(:metadata)], fn meta ->
      %{
        meta
        | first_disrupted_stop:
            if(meta.first_disrupted_stop >= at_index,
              do: meta.first_disrupted_stop + 1,
              else: meta.first_disrupted_stop
            ),
          last_disrupted_stop:
            if(meta.last_disrupted_stop >= at_index,
              do: meta.last_disrupted_stop + 1,
              else: meta.last_disrupted_stop
            ),
          home_stop: if(meta.home_stop >= at_index, do: meta.home_stop + 1, else: meta.home_stop),
          length: meta.length + 1
      }
    end)
  end

  defp remove_stops(builder, indices) do
    orig_first_disrupted_stop_id = builder.sequence[builder.metadata.first_disrupted_stop].id
    orig_last_disrupted_stop_id = builder.sequence[builder.metadata.last_disrupted_stop].id
    orig_home_stop_id = builder.sequence[builder.metadata.home_stop].id

    builder =
      update_in(builder.sequence, fn seq ->
        seq
        |> Map.drop(indices)
        |> Enum.sort_by(fn {index, _stop_data} -> index end)
        |> Enum.map(fn {_index, stop_data} -> stop_data end)
        |> Enum.with_index(fn stop_data, i -> {i, stop_data} end)
        |> Map.new()
      end)

    update_in(builder.metadata, fn meta ->
      first_disrupted_stop =
        Enum.find_value(builder.sequence, fn {index, stop_data} ->
          if(stop_data.id == orig_first_disrupted_stop_id, do: index)
        end)

      last_disrupted_stop =
        Enum.find_value(builder.sequence, fn {index, stop_data} ->
          if(stop_data.id == orig_last_disrupted_stop_id, do: index)
        end)

      home_stop =
        Enum.find_value(builder.sequence, fn {index, stop_data} ->
          if(stop_data.id == orig_home_stop_id, do: index)
        end)

      %{
        meta
        | first_disrupted_stop: first_disrupted_stop,
          last_disrupted_stop: last_disrupted_stop,
          home_stop: home_stop,
          length: map_size(builder.sequence)
      }
    end)
  end

  @doc "Serializes the builder to a list of slots."
  @spec to_slots(t()) :: list(Model.slot())
  def to_slots(%__MODULE__{} = builder) do
    # use ArrowSlot struct

    builder.sequence
    |> Enum.sort_by(fn {index, _slot} -> index end)
    |> Enum.map(fn
      {_index, %ArrowSlot{} = arrow} -> %{type: :arrow, label_id: arrow.label_id}
      {_index, %StopSlot{} = stop} when stop.terminal? -> %{type: :terminal, label_id: stop.id}
      {_index, %StopSlot{} = stop} -> %{label: stop.label, show_symbol: true}
      {_index, %OmittedSlot{} = omitted} -> %{label: omitted.label, show_symbol: false}
    end)
  end

  defp get_end_slot(_line, []), do: []

  defp get_end_slot(_line, [%{terminal?: true} = stop_data]), do: [stop_data]

  defp get_end_slot(line, stops) do
    stop_ids = Enum.map(stops, & &1.id)

    label_id = Model.get_end_label_id(line, stop_ids)

    [%ArrowSlot{label_id: label_id}]
  end

  @doc """
  Returns the number of slots that would be in the diagram produced by the current builder.
  """
  @spec slot_count(t()) :: non_neg_integer()
  def slot_count(%__MODULE__{} = builder) do
    left_end_slot_count = min(map_size(builder.left_omitted), 1)
    right_end_slot_count = min(map_size(builder.right_omitted), 1)

    map_size(builder.sequence) + left_end_slot_count + right_end_slot_count
  end

  @doc """
  Returns a sorted list of indices of the stops that are in the alert's informed entities.
  For station closures, this is the stops that are bypassed.
  For shuttles and suspensions, this is the stops that don't have any train service
  *as well as* the stops at the boundary of the disruption that don't have train service in one direction.
  """
  @spec disrupted_stop_indices(t()) :: list(index())
  def disrupted_stop_indices(%__MODULE__{} = builder) do
    builder.sequence
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
  def closure_count(%__MODULE__{} = builder) do
    builder
    |> closure_indices()
    |> Enum.count()
  end

  # The closure has highest priority, so no other overlapping region can take stops from it.
  defp closure_indices(builder), do: closure_ideal_indices(builder)

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
  Returns the number of stops comprising the ends of the diagram.

  This is normally 2, unless the closure region overlaps with one end.
  """
  @spec end_count(t()) :: non_neg_integer()
  def end_count(%__MODULE__{} = builder) do
    builder
    |> end_indices()
    |> Enum.count()
  end

  # Parts of the end region can be subsumed by the closure region.
  defp end_indices(builder) do
    end_region = MapSet.new(end_ideal_indices(builder))

    closure_region = MapSet.new(closure_ideal_indices(builder))

    MapSet.difference(end_region, closure_region)
  end

  defp end_ideal_indices(builder) do
    [0, builder.metadata.length - 1]
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

  # The current location region has lowest priority, can be subsumed by any other region.
  defp current_location_indices(builder) do
    current_location_region = MapSet.new(current_location_ideal_indices(builder))

    gap_region = MapSet.new(gap_ideal_indices(builder))
    closure_region = MapSet.new(closure_ideal_indices(builder))
    end_region = MapSet.new(end_ideal_indices(builder))

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
  def effect(%__MODULE__{} = builder), do: builder.metadata.effect

  @spec line(t()) :: Model.line_color()
  def line(%__MODULE__{} = builder), do: builder.metadata.line

  def current_station_index(%__MODULE__{} = builder),
    do: builder.metadata.home_stop

  # Adjusts an index to be within the bounds of the stop sequence.
  defp clamp(index, _metadata) when index < 0, do: 0
  defp clamp(index, metadata) when index >= metadata.length, do: metadata.length - 1
  defp clamp(index, _metadata), do: index

  def add_back_end_slots(builder) do
    left_end = get_end_slot(builder.metadata.line, Map.values(builder.left_omitted))
    right_end = get_end_slot(builder.metadata.line, Map.values(builder.right_omitted))

    builder =
      case left_end do
        [] -> builder
        [slot] -> insert_stop(builder, 0, slot)
      end

    builder =
      case right_end do
        [] -> builder
        [slot] -> insert_stop(builder, builder.metadata.length, slot)
      end
  end
end
