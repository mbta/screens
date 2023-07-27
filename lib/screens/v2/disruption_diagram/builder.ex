defmodule Screens.V2.DisruptionDiagram.Builder do
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

  @enforce_keys [:sequence, :metadata]
  defstruct @enforce_keys ++ [left_end: Vector.new(), right_end: Vector.new()]

  @type t :: %__MODULE__{
          sequence: sequence(),
          metadata: metadata(),
          left_end: end_sequence(),
          right_end: end_sequence()
        }

  # Starts out only containing StopSlots, but may contain other slot types
  # as we work our way toward building the final diagram output.
  @opaque sequence :: Vector.t(StopSlot.t() | OmittedSlot.t() | ArrowSlot.t())

  @opaque end_sequence :: Vector.t(StopSlot.t() | ArrowSlot.t())

  @opaque metadata :: %{
            line: Model.line_color(),
            effect: :shuttle | :suspension | :station_closure,
            first_disrupted_stop: Vector.index(),
            last_disrupted_stop: Vector.index(),
            home_stop: Vector.index(),
            branch: :b | :c | :d | :e
          }

  @doc "Creates a new Builder from a localized alert."
  @spec new(LocalizedAlert.t()) :: {:ok, t()} | :error
  def new(localized_alert) do
    informed_stop_ids =
      for %{stop: "place-" <> _ = stop_id} <- localized_alert.alert.informed_entities do
        stop_id
      end
      |> MapSet.new()

    informed_route_id =
      localized_alert.alert.informed_entities
      |> Enum.find_value(fn
        %{route: "Green" <> _ = route_id} -> route_id
        %{route: route_id} when route_id in ["Blue", "Orange", "Red"] -> route_id
        _ -> false
      end)

    {branch, informed_route_id} =
      case informed_route_id do
        "Green-" <> branch_letter ->
          trunk_stop_ids = MapSet.new(Stop.gl_trunk_stops(), &elem(&1, 0))

          if MapSet.subset?(
               MapSet.new(
                 MapSet.put(informed_stop_ids, localized_alert.location_context.home_stop)
               ),
               trunk_stop_ids
             ) do
            {nil, "Green"}
          else
            branch =
              branch_letter
              |> String.downcase()
              |> String.to_existing_atom()

            {branch, informed_route_id}
          end

        _ ->
          {nil, informed_route_id}
      end

    line = Route.get_color_for_route(informed_route_id)

    stop_id_to_name = Stop.stop_id_to_name(informed_route_id)

    home_stop_id = localized_alert.location_context.home_stop

    selected_sequence =
      if line == :green and is_nil(branch) do
        # It's a GL trunk alert!
        # Let's use trunk stops for the sequence.
        Enum.map(Stop.gl_trunk_stops(), &elem(&1, 0))
      else
        Enum.find(localized_alert.location_context.stop_sequences, fn sequence ->
          sequence_set = MapSet.new(sequence)
          MapSet.subset?(informed_stop_ids, sequence_set)
        end)
      end

    case selected_sequence do
      nil ->
        # There's no stop sequence that contains both the home stop and the informed stops.
        :error

      selected_sequence ->
        stop_sequence =
          Enum.map(selected_sequence, fn stop_id ->
            {stop_id, Map.fetch!(stop_id_to_name, stop_id)}
          end)

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
          |> then(fn seq ->
            if line == :green and branch == nil do
              # For GL trunk alerts only, we do not want to mark ends of the sequence (Lechmere & Kenmore) as terminals.
              seq
            else
              seq
              |> Vector.update_at!(0, &%{&1 | terminal?: true})
              |> Vector.update_at!(-1, &%{&1 | terminal?: true})
            end
          end)

        init_metadata = %{
          line: Route.get_color_for_route(informed_route_id),
          branch: branch,
          effect: localized_alert.alert.effect
        }

        %__MODULE__{sequence: sequence, metadata: init_metadata}
        |> recalculate_metadata()
        |> split_end_stops()
        |> validate()
    end
  end

  defp validate(%{metadata: %{line: non_branching}} = builder)
       when non_branching in [:blue, :orange] do
    {:ok, builder}
  end

  defp validate(%{metadata: %{line: :red}} = builder) do
    # Ensure that this alert does not cross from the trunk to a branch.
    disrupted_indices = disrupted_stop_indices(builder)

    jfk_index = Aja.Enum.find_index(builder.sequence, &(&1.id == "place-jfk"))

    if not is_nil(jfk_index) and Enum.any?(disrupted_indices, &(&1 <= jfk_index)) and
         Enum.any?(disrupted_indices, &(&1 > jfk_index)) do
      :error
    else
      # it's definitely ok, but we might be able to label right end
      cond do
        is_nil(jfk_index) ->
          # No branch points in sequence. Validation succeeds and we can immediately label right end if it contains the branch point.
          {:ok, maybe_add_ashmont_braintree_label(builder)}

        jfk_index == vec_size(builder.sequence) - 1 ->
          # Branch point is last. It's a trunk alert and we can immediately label right end.
          {:ok,
           %{builder | right_end: Vector.new([%ArrowSlot{label_id: "place-asmnl+place-brntn"}])}}

        jfk_index == vec_size(builder.sequence) - 2 ->
          # Branch point is second-to-last. Some extra steps are involved for this case.
          {:ok, trim_past_jfk(builder)}

        true ->
          {:ok, builder}
      end
    end
  end

  defp validate(%{metadata: %{line: :green, branch: nil}} = builder) do
    # Trunk alert.
    # Stop sequence is Lechmere <-> Kenmore.
    # Since we've already removed all branch stops, we don't need to do any trimming.

    builder =
      builder
      |> update_in(
        [Access.key(:left_end)],
        &Vector.prepend(&1, %ArrowSlot{label_id: "place-mdftf+place-unsqu"})
      )
      |> update_in(
        [Access.key(:right_end)],
        &Vector.append(&1, %ArrowSlot{label_id: "western_branches"})
      )

    {:ok, builder}

    # Both ends will ALWAYS be destination-arrows.
    # Determing labels later in get_end_label--
    #
    # Left end possible labels:
    # - Lechmere is in left_end: to Medford/Tufts & Union Sq
    # - if Lechmere is first in sequence, the prepended arrow slot will cover us.
    #
    # Right end possible labels (check cases one by one in this order):
    # - North Station is in right_end: to North Station & Park St
    # - Gov Ctr is in right_end: to Government Center
    # - Copley is in right_end: to Copley & West
    # - Kenmore is in right_end: to Kenmore & West
    # - If Kenmore is last in sequence, the appended arrow slot will cover us.

    # If Lechmere is in left_end or first in sequence, then replace left_end contents with arrow to Medford/Tufts & Union Sq

    # ALWAYS reverse the builder

    # Example: home stop is Gov Ctr. Copley is bypassed.
    # We might use E branch stop sequence for this.

    #
  end

  # For any alert that informs only one branch, it's immediately valid
  # and we don't need to do any stop trimming because there's only one line of stops on that branch.

  defp validate(%{metadata: %{line: :green, branch: :b}} = builder) do
    # Boston College (B) branch - to Gov Ctr
    # Gov Ctr end labeling can be handled normally

    # One end label will ALWAYS be BC, the other will ALWAYS be Gov Ctr (maybe arrows for one or the other)
    # No trimming necessary

    # ALWAYS reverse the builder

    # Nothing to do here?
    {:ok, builder}
  end

  defp validate(%{metadata: %{line: :green, branch: :c}} = builder) do
    # Cleveland Circle (C) branch - to Gov Ctr
    # Gov Ctr end labeling can be handled normally

    # One end label will ALWAYS be Cleveland Cir, the other will ALWAYS be Gov Ctr (maybe arrows for one or the other)
    # No trimming necessary

    # ALWAYS reverse the builder

    # Nothing to do here?
    {:ok, builder}
  end

  defp validate(%{metadata: %{line: :green, branch: :d}} = builder) do
    # Riverside (D) branch - to Union Sq on other end
    # Branching: Kenmore & Lechmere

    # One end will ALWAYS be Union Sq, the other will ALWAYS be Riverside (maybe arrows)
    # No trimming necessary--we've narrowed it down to one branch so there's no problem with ambiguity

    # Reverse the builder if the western branch contains informed stops
    {:ok, builder}
  end

  defp validate(%{metadata: %{line: :green, branch: :e}} = builder) do
    # Heath St (E) branch - to Medford/Tufts on other end
    # Branching: Copley & Lechmere

    # One end will ALWAYS be Medford/Tufts, the other will ALWAYS be Heath St (maybe arrows)
    # No trimming necessary--we've narrowed it down to one branch so there's no problem with ambiguity

    # Reverse the builder if the western branch contains informed stops
    {:ok, builder}
  end

  defp trim_past_jfk(%{metadata: %{line: :red}} = builder) do
    # If JFK is second-to-last and the alert is valid, that means it's a trunk alert.
    # We need to trim the undisrupted branch stop off the end to make destination labeling work.
    %{
      builder
      | sequence: Vector.delete_last!(builder.sequence),
        right_end: Vector.new([%ArrowSlot{label_id: "place-asmnl+place-brntn"}])
    }
    |> recalculate_metadata()
  end

  defp maybe_add_ashmont_braintree_label(builder) do
    case Aja.Enum.find_index(builder.right_end, &(&1.id == "place-jfk")) do
      nil ->
        builder

      jfk_index ->
        # JFK is in the right end. Remove everything past it so we can't use branch stops for padding.
        new_right_end = Vector.take(builder.right_end, jfk_index + 1)
        %{builder | right_end: new_right_end}
    end
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
    meta_without_indices = Map.take(builder.metadata, [:line, :effect, :branch])

    builder.sequence
    |> Vector.with_index()
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

    if target_slots >= region_length do
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

    # # Check if any stops we're about to omit are either
    # # - the home stop, or
    # # - a bypassed stop in a station closure alert.
    # important_omitted_stops =
    #   for i <- omitted_indices,
    #       stop_data = builder.sequence[i],
    #       stop_data.home_stop? or
    #         (builder.metadata.effect == :station_closure and stop_data.disrupted?),
    #       do: {stop_data, i}

    # if important_omitted_stops != [] do
    #   # Uh oh! We tried to omit one or more important stop(s).
    #   # Do some extra work to see if we can omit stops around it instead.
    #   do_multi_omit(
    #     builder,
    #     current_region_indices,
    #     target_slots,
    #     label_callback,
    #     important_omitted_stops
    #   )
    # else
    # All is good, proceed with the omission.
    label =
      omitted_indices
      |> MapSet.new(&builder.sequence[&1].id)
      |> label_callback.()

    {first_omitted, last_omitted} = Enum.min_max(omitted_indices)

    builder
    |> update_in([Access.key(:sequence)], fn seq ->
      left_side = Vector.slice(seq, 0..(first_omitted - 1)//1)

      right_side = Vector.slice(seq, (last_omitted + 1)..-1//1)

      left_side +++ Vector.new([%OmittedSlot{label: label}]) +++ right_side
    end)
    |> recalculate_metadata()

    # end
  end

  # defp do_multi_omit(builder, _current_region_indices, _target_slots, _label_callback, [
  #        _important_stop_index
  #      ]) do
  #   # TODO
  #   builder

  #   # 1. Check if there's enough space to the left or the right of the important stop to
  #   #    do the omission.
  #   # 2. If not, try to do 2 omissions, one on either side.
  #   # 3. Give up!
  # end

  # defp do_multi_omit(
  #        _builder,
  #        _current_region_indices,
  #        _target_slots,
  #        _label_callback,
  #        _important_stop_indices
  #      ) do
  #   # ...Just give up?? This is exceedingly rare--only possible in a very large station closure
  #   Logger.warn("[uncollapsible disruption diagram]")
  #   raise "Can't omit enough stops from diagram"
  # end

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

    # If we just added the last slot from the right end, all we did was move
    # a terminal/arrow back into the main sequence.
    # Effectively, nothing was added to the diagram.
    new_num_to_add = if vec_size(new_right_end) > 0, do: num_to_add - 1, else: num_to_add

    builder
    |> put_in([Access.key(:right_end)], new_right_end)
    |> update_in([Access.key(:sequence)], &Vector.append(&1, stop_data))
    |> do_add_slots(new_num_to_add, :right_end)
  end

  defp do_add_slots(builder, num_to_add, :left_end) do
    {stop_data, new_left_end} = Vector.pop_last!(builder.left_end)

    # If we just added the last slot from the left end, all we did was move
    # a terminal/arrow back into the main sequence.
    # Effectively, nothing was added to the diagram.
    new_num_to_add = if vec_size(new_left_end) > 0, do: num_to_add - 1, else: num_to_add

    builder
    |> put_in([Access.key(:left_end)], new_left_end)
    |> update_in([Access.key(:sequence)], &Vector.prepend(&1, stop_data))
    |> do_add_slots(new_num_to_add, :left_end)
  end

  @doc "Serializes the builder to a Model.serialized_response()."
  @spec serialize(t()) :: Model.serialized_response()
  def serialize(builder) do
    builder = add_back_end_slots(builder)

    base_data = %{
      effect: builder.metadata.effect,
      line: builder.metadata.line,
      current_station_slot_index: builder.metadata.home_stop,
      slots: to_slots(builder)
    }

    if base_data.effect == :station_closure do
      Map.put(
        base_data,
        :closed_station_slot_indices,
        disrupted_stop_indices(builder)
      )
    else
      range =
        builder
        |> disrupted_stop_indices()
        |> Enum.min_max()

      Map.put(base_data, :effect_region_slot_index_range, range)
    end
  end

  defp to_slots(%__MODULE__{} = builder) do
    Aja.Enum.map(builder.sequence, fn
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
  defp add_back_end_slots(builder) do
    left_end = get_end_slot(builder.metadata, builder.left_end)
    right_end = get_end_slot(builder.metadata, builder.right_end)

    %{builder | sequence: left_end +++ builder.sequence +++ right_end}
    |> recalculate_metadata()
  end

  defp get_end_slot(_meta, vec([])), do: Vector.new()

  defp get_end_slot(_meta, vec([%{terminal?: true} = stop_data])), do: Vector.new([stop_data])

  defp get_end_slot(_meta, vec([%ArrowSlot{} = predefined_destination])),
    do: Vector.new([predefined_destination])

  defp get_end_slot(%{line: :green} = meta, stops) do
    stop_ids =
      stops
      |> Vector.filter(&is_struct(&1, StopSlot))
      |> Aja.Enum.map(& &1.id)

    label_id = Model.get_gl_end_label_id(meta.branch, stop_ids)

    Vector.new([%ArrowSlot{label_id: label_id}])
  end

  defp get_end_slot(meta, stops) do
    stop_ids = Aja.Enum.map(stops, & &1.id)

    label_id = Model.get_end_label_id(meta.line, stop_ids)

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

  # Returns a sorted list of indices of the stops that are in the alert's informed entities.
  # For station closures, this is the stops that are bypassed.
  # For shuttles and suspensions, this is the stops that don't have any train service
  # *as well as* the stops at the boundary of the disruption that don't have train service in one direction.
  defp disrupted_stop_indices(%__MODULE__{} = builder) do
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
    |> Enum.min_max(fn -> :its_empty end)
    |> case do
      {left, right} -> left..right//1
      :its_empty -> ..
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
    min(1, vec_size(builder.left_end)) + min(1, vec_size(builder.right_end))
  end

  @spec effect(t()) :: :shuttle | :suspension | :station_closure
  def effect(%__MODULE__{} = builder), do: builder.metadata.effect

  @spec line(t()) :: Model.line_color()
  def line(%__MODULE__{} = builder), do: builder.metadata.line

  # Adjusts an index to be within the bounds of the stop sequence.
  defp clamp(index, _sequence_size) when index < 0, do: 0
  defp clamp(index, sequence_size) when index >= sequence_size, do: sequence_size - 1
  defp clamp(index, _sequence_size), do: index
end
