defmodule Screens.V2.DisruptionDiagram.Builder do
  @moduledoc """
  An intermediate data structure for transforming a localized alert to a disruption diagram.

  Values should be accessed/manipulated only via public module functions.
  """

  alias Aja.Vector
  alias Screens.Routes.Route
  alias Screens.Stops.{Stop, Subway}
  alias Screens.V2.DisruptionDiagram, as: DD
  alias Screens.V2.DisruptionDiagram.Label
  alias Screens.V2.LocalizedAlert

  # Vector-related macros
  import Aja, only: [vec: 1, vec_size: 1, +++: 2]

  ##################
  # HELPER MODULES #
  ##################

  defmodule StopSlot do
    @moduledoc false

    @enforce_keys [:id, :label, :home_stop?, :disrupted?, :terminal?]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            id: Stop.id(),
            label: DD.label_map(),
            home_stop?: boolean(),
            disrupted?: boolean(),
            terminal?: boolean()
          }
  end

  defmodule OmittedSlot do
    @moduledoc false

    @enforce_keys [:label]
    defstruct @enforce_keys

    @type t :: %__MODULE__{label: DD.label()}
  end

  defmodule ArrowSlot do
    @moduledoc false

    @enforce_keys [:label_id]
    defstruct @enforce_keys

    @type t :: %__MODULE__{label_id: DD.end_label_id()}
  end

  defmodule Metadata do
    @moduledoc false

    @enforce_keys [
      :line,
      :effect,
      :branch,
      :home_stop,
      :first_disrupted_stop,
      :last_disrupted_stop
    ]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            line: DD.line(),
            effect: :shuttle | :suspension | :station_closure,
            branch: DD.branch(),
            first_disrupted_stop: Vector.index(),
            last_disrupted_stop: Vector.index(),
            home_stop: Vector.index()
          }
  end

  ###############
  # MAIN MODULE #
  ###############

  @enforce_keys [:sequence, :metadata]
  defstruct @enforce_keys ++ [left_end: Vector.new(), right_end: Vector.new()]

  @type t :: %__MODULE__{
          # The main sequence of slots in the diagram.
          sequence: sequence(),
          # Information about the diagram as a whole, including indexes of important stops.
          metadata: metadata(),
          # The ends are "bags" of stops that are outside the main area of the diagram.
          # Stops can be transferred between the `sequence` and the ends during the process of building the diagram.
          # Each end serializes to at most 1 slot in the final diagram.
          # During serialization, we inspect the contents of each end to determine what the first
          # and last slot should be.
          left_end: end_sequence(),
          right_end: end_sequence()
        }

  # Starts out only containing StopSlots, but may contain other slot types
  # as we work our way toward building the final diagram output.
  @opaque sequence :: Vector.t(StopSlot.t() | OmittedSlot.t() | ArrowSlot.t())

  @opaque end_sequence :: Vector.t(StopSlot.t() | ArrowSlot.t())

  @opaque metadata :: Metadata.t()

  @doc "Creates a new Builder from a localized alert."
  @spec new(LocalizedAlert.t()) :: {:ok, t()} | {:error, reason :: String.t()}
  def new(localized_alert) do
    informed_stop_ids =
      for %{stop: "place-" <> _ = stop_id} <- localized_alert.alert.informed_entities,
          into: MapSet.new(),
          do: stop_id

    with {:ok, route_id, stop_sequence, branch} <-
           get_builder_data(localized_alert, informed_stop_ids) do
      line =
        case route_id do
          "Mattapan" -> :mattapan
          _ -> Route.color(route_id)
        end

      stop_names = Subway.route_stop_names(route_id)

      slot_sequence =
        stop_sequence
        |> Vector.new(fn stop_id ->
          {full, abbrev} = Map.fetch!(stop_names, stop_id)

          %StopSlot{
            id: stop_id,
            label: %{full: full, abbrev: abbrev},
            home_stop?: stop_id == localized_alert.location_context.home_stop,
            disrupted?: stop_id in informed_stop_ids,
            terminal?: false
          }
        end)
        |> adjust_ends(line, branch)

      init_metadata = %Metadata{
        line: line,
        branch: branch,
        effect: localized_alert.alert.effect,
        # These will get the correct values during the first `recalculate_metadata` run below.
        home_stop: -1,
        first_disrupted_stop: -1,
        last_disrupted_stop: -1
      }

      builder =
        %__MODULE__{sequence: slot_sequence, metadata: init_metadata}
        |> recalculate_metadata()
        |> split_end_stops()

      {:ok, builder}
    end
  end

  @doc """
  Reverses the builder's internal stop sequence, so that the last stop comes first and vice versa.

  This is helpful for cases where the disruption diagram lists stops in the opposite order of
  the direction_id=0 route order, e.g. in Blue Line diagrams where we show Bowdoin first but
  direction_id=0 has Wonderland listed first.
  """
  @spec reverse(t()) :: t()
  def reverse(%__MODULE__{} = builder) do
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
  Tries to omit stops from the given region, replacing them with a labeled "blank" slot, or two in rare cases.
  `target_slots` gives the desired number of remaining slots in the region after omission.

  Stops are omitted from the center of the region, unless that would result
  in the omission of the home stop or a skipped stop.
  In that case, we try to find another segment, or segments, of stops to omit, staying as close to the center as possible.

  Returns an error result if it's not possible to omit the required number of stops without
  also omitting the home stop or a skipped stop.
  """
  @spec try_omit_stops(t(), :closure | :gap, pos_integer()) ::
          {:ok, t()} | {:error, reason :: String.t()}
  def try_omit_stops(builder, region, target_slots)

  def try_omit_stops(%__MODULE__{} = builder, :closure, target_closure_slots) do
    try_omit(builder, closure_indices(builder), target_closure_slots)
  end

  def try_omit_stops(%__MODULE__{} = builder, :gap, target_gap_stops) do
    try_omit(builder, gap_indices(builder), target_gap_stops)
  end

  @doc """
  Moves `num_to_add` stops back from the left/right end groups to the main sequence,
  effectively "padding" the diagram with stops that otherwise would have been
  omitted inside one of the destination-arrow slots.
  Stops are added from the end closest to the home stop, unless it's empty.
  In that case, they are added from the opposite end.
  """
  @spec add_slots(t(), pos_integer()) :: t()
  def add_slots(%__MODULE__{} = builder, num_to_add) do
    closure_region_indices = closure_indices(builder)

    home_stop_is_right_of_center = builder.metadata.home_stop > center(closure_region_indices)

    pull_from = if home_stop_is_right_of_center, do: :right_end, else: :left_end

    builder
    |> do_add_slots(num_to_add, pull_from)
    |> recalculate_metadata()
  end

  @doc "Serializes the builder to a DisruptionDiagram.serialized_response()."
  @spec serialize(t()) :: DD.serialized_response()
  def serialize(%__MODULE__{} = builder) do
    builder = add_back_end_slots(builder)

    base_data = %{
      effect: builder.metadata.effect,
      line: builder.metadata.line,
      current_station_slot_index: builder.metadata.home_stop,
      slots: serialize_sequence(builder)
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
  Returns the number of stops comprising the closure region of the diagram.

  **This can be different from the number of disrupted stops!**

  For station closures, we count from the stop on the left of the first skipped stop to the stop on the right of the last skipped stop:
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

  @doc """
  Returns the number of stops comprising the gap region of the diagram.

  This is always the stops between the closure region and the home stop.
  """
  @spec gap_count(t()) :: non_neg_integer()
  def gap_count(%__MODULE__{} = builder) do
    Enum.count(gap_indices(builder))
  end

  @doc """
  Returns the number of stops comprising the "current location" region
  of the diagram.

  This is normally 2: the actual home stop, and its adjacent stop
  on the far side of the closure. Its adjacent stop on the near side is
  part of the gap.

  The number is lower when the closure region overlaps with this region,
  or when the home stop is at/near a terminal.
  """
  @spec current_location_count(t()) :: non_neg_integer()
  def current_location_count(%__MODULE__{} = builder) do
    builder
    |> current_location_indices()
    |> Enum.count()
  end

  @doc """
  Returns the number of stops comprising the ends of the diagram.

  This is normally 2, unless another region contains either terminal stop of the line.
  """
  @spec end_count(t()) :: non_neg_integer()
  def end_count(%__MODULE__{} = builder) do
    min(1, vec_size(builder.left_end)) + min(1, vec_size(builder.right_end))
  end

  @spec line(t()) :: DD.line()
  def line(%__MODULE__{} = builder), do: builder.metadata.line

  @spec branch(t()) :: DD.branch()
  def branch(%__MODULE__{} = builder), do: builder.metadata.branch

  @doc """
  Returns true if this diagram is
  - for a Green Line alert,
  - includes at least one GLX stop (past Lechmere), and
  - does not extend west of Copley.
  """
  @spec glx_only?(t()) :: boolean()
  def glx_only?(%__MODULE__{} = builder) do
    is_glx_branch = builder.metadata.branch in [:d, :e]

    diagram_contains_glx =
      Aja.Enum.any?(builder.sequence, fn
        %StopSlot{} = stop_data -> Subway.glx_stop?(stop_data.id)
        _ -> false
      end)

    copley_index =
      Aja.Enum.find_index(builder.sequence, fn
        %StopSlot{id: "place-coecl"} -> true
        _ -> false
      end)

    no_stops_west_of_copley =
      case copley_index do
        nil -> true
        # If Copley is in the sequence, it can only be the last stop
        i -> i == vec_size(builder.sequence) - 1
      end

    is_glx_branch and diagram_contains_glx and no_stops_west_of_copley
  end

  # Gets all the stuff we need to assemble the struct.
  @spec get_builder_data(LocalizedAlert.t(), MapSet.t(Stop.id())) ::
          {:ok, informed_route :: Route.id(), stop_sequence :: list(Stop.id()), DD.branch()}
          | {:error, String.t()}
  defp get_builder_data(localized_alert, informed_stop_ids) do
    stops_in_diagram = MapSet.put(informed_stop_ids, localized_alert.location_context.home_stop)

    matching_tagged_sequences =
      Enum.flat_map(localized_alert.location_context.tagged_stop_sequences, fn {route, sequences} ->
        sequences
        |> Enum.filter(&MapSet.subset?(stops_in_diagram, MapSet.new(&1)))
        |> Enum.map(&{route, &1})
      end)

    informed_route_id =
      Enum.find_value(localized_alert.alert.informed_entities, fn
        %{route: "Green" <> _ = route_id} -> route_id
        %{route: route_id} when route_id in ["Blue", "Orange", "Red"] -> route_id
        _ -> false
      end)

    do_get_data(matching_tagged_sequences, informed_route_id)
  end

  defp do_get_data([], _) do
    {:error, "no stop sequence contains both the home stop and all informed stops"}
  end

  # A single Green Line branch
  defp do_get_data([{"Green-" <> branch_letter = route_id, sequence}], _) do
    branch =
      branch_letter
      |> String.downcase()
      |> String.to_existing_atom()

    {:ok, route_id, sequence, branch}
  end

  # A single Red Line branch
  defp do_get_data([{"Red", sequence}], _) do
    branch = if "place-asmnl" in sequence, do: :ashmont, else: :braintree

    {:ok, "Red", sequence, branch}
  end

  # A single non-branching route
  defp do_get_data([{route_id, sequence}], _) do
    {:ok, route_id, sequence, :trunk}
  end

  # 2+ routes
  defp do_get_data(matches, informed_route_id) do
    cond do
      Enum.all?(matches, &match?({"Green-" <> _, _}, &1)) ->
        # Green Line trunk
        {:ok, "Green", gl_trunk_stop_sequence(), :trunk}

      Enum.all?(matches, &match?({"Red", _}, &1)) ->
        # Red Line trunk
        {:ok, "Red", rl_trunk_stop_sequence(), :trunk}

      # The remaining cases are for when 2+ lines contain the stop(s). We defer to informed route.
      # Only core stops are served by more than one line, so we'll use the trunk sequences for GL/RL.
      String.starts_with?(informed_route_id, "Green") ->
        # Green Line trunk, probably at North Station, Haymarket, Government Center, or Park Street
        {:ok, "Green", gl_trunk_stop_sequence(), :trunk}

      informed_route_id == "Red" ->
        # Red Line trunk, probably at Park Street or Downtown Crossing
        {:ok, "Red", rl_trunk_stop_sequence(), :trunk}

      true ->
        # Orange Line, probably at North Station, Haymarket, State, or Downtown Crossing
        # or Blue Line, probably at Government Center or State
        {:ok, informed_route_id, Subway.route_stop_sequence(informed_route_id), :trunk}
    end
  end

  defp gl_trunk_stop_sequence do
    Enum.map(Subway.gl_trunk_stops(), fn {stop_id, _labels} -> stop_id end)
  end

  defp rl_trunk_stop_sequence do
    Enum.map(Subway.rl_trunk_stops(), fn {stop_id, _labels} -> stop_id end)
  end

  # Adjusts the left and right ends of the sequence before we split them off into `left_end` and `right_end`.
  # - Mark terminal stops as such
  # - For branching ends of trunk sequences (JFK, Lechmere, Kenmore), add `ArrowSlot`s with labels for those branches.
  defp adjust_ends(sequence, line, branch)

  defp adjust_ends(sequence, :green, :trunk) do
    # The Green Line trunk (Lechmere to Kenmore) has branches at both ends.
    sequence
    |> Vector.prepend(%ArrowSlot{label_id: "place-mdftf+place-unsqu"})
    |> Vector.append(%ArrowSlot{label_id: "western_branches"})
  end

  defp adjust_ends(sequence, :red, :trunk) do
    # The Red Line trunk (Alewife to JFK) has a terminal at Alewife and branches past JFK.
    sequence
    |> Vector.update_at!(0, &%{&1 | terminal?: true})
    |> Vector.append(%ArrowSlot{label_id: "place-asmnl+place-brntn"})
  end

  defp adjust_ends(sequence, _line, _branch) do
    # All other stop sequences have terminals at both ends.
    sequence
    |> Vector.update_at!(0, &%{&1 | terminal?: true})
    |> Vector.update_at!(-1, &%{&1 | terminal?: true})
  end

  # Removes stops outside the closure/current location regions from the main sequence, and puts them into the ends.
  # O = O = O = O = X = X = X = X = O = O = <> = O = O = O = =>
  # ^   ^   ^   ^                                    ^   ^   ^
  # Moved to left_end                                Moved to right_end
  defp split_end_stops(builder)
       when builder.metadata.line == :blue or builder.metadata.line == :mattapan do
    # Since we always show all stops for the Blue Line and Mattapan, we don't need to do
    # anything special with the ends. They don't need to be split out.
    builder
  end

  defp split_end_stops(builder) do
    # In all other cases, we split out the left and right ends.

    in_diagram =
      [
        closure_indices(builder),
        gap_indices(builder),
        # We can save a little work by using the "ideal" indices here, since
        # any overlap will disappear when we drop these into a MapSet.
        current_location_ideal_indices(builder)
      ]
      |> Enum.concat()
      |> MapSet.new()

    {leftmost_stop_index, rightmost_stop_index} = Enum.min_max(in_diagram)

    # Example: If the first one we're keeping is at index 5,
    # then it's the 6th element so we need to slice off the first 5.
    left_slice_amount = leftmost_stop_index

    last_index = Vector.size(builder.sequence) - 1
    right_slice_amount = last_index - rightmost_stop_index

    builder
    |> split_end(:right_end, right_slice_amount)
    |> split_end(:left_end, left_slice_amount)
    |> recalculate_metadata()
  end

  defp split_end(builder, end_field, 0), do: %{builder | end_field => Vector.new()}

  defp split_end(builder, :left_end, amount) do
    {left_end, sequence} = Vector.split(builder.sequence, amount)

    # (We expect recalculate_metadata to be invoked in the calling function, so don't do it here.)
    %{builder | sequence: sequence, left_end: left_end}
  end

  defp split_end(builder, :right_end, amount) do
    {sequence, right_end} = Vector.split(builder.sequence, -amount)

    %{builder | sequence: sequence, right_end: right_end}
  end

  # Re-computes index fields (home_stop, first/last_disrupted_stop)
  # in builder.metadata after builder.sequence is changed.
  #
  # This function must be called after any operation that changes builder.sequence.
  defp recalculate_metadata(builder) do
    # We're going to replace all of the indices, so throw out the old ones.
    # That way, if we fail to set one of them (which shouldn't happen),
    # the `struct!` call below will fail instead of continuing with missing data.
    meta_without_indices =
      builder.metadata
      |> Map.from_struct()
      |> Map.drop([:home_stop, :first_disrupted_stop, :last_disrupted_stop])

    indexed_sequence = Vector.with_index(builder.sequence)

    home_stop =
      Aja.Enum.find_value(indexed_sequence, fn
        {%StopSlot{home_stop?: true}, i} -> i
        _ -> false
      end)

    first_disrupted_stop =
      Aja.Enum.find_value(indexed_sequence, fn
        {%StopSlot{disrupted?: true}, i} -> i
        _ -> false
      end)

    last_disrupted_stop =
      indexed_sequence
      |> Vector.reverse()
      |> Aja.Enum.find_value(fn
        {%StopSlot{disrupted?: true}, i} -> i
        _ -> false
      end)

    new_metadata =
      meta_without_indices
      |> Map.merge(%{
        home_stop: home_stop,
        first_disrupted_stop: first_disrupted_stop,
        last_disrupted_stop: last_disrupted_stop
      })
      |> then(&struct!(Metadata, &1))

    %{builder | metadata: new_metadata}
  end

  defp try_omit(builder, current_region_indices, target_slots) do
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

    home_stop_is_right_of_center = builder.metadata.home_stop > center(current_region_indices)

    # If the number of slots to keep is odd, more slots are devoted to the side of the region nearest the home stop.
    offset =
      if rem(num_to_keep, 2) == 1 and not home_stop_is_right_of_center do
        # num_to_keep is odd and the home stop is NOT to the right of the closure center.
        div(num_to_keep, 2) + 1
      else
        # num_to_keep is even, OR num_to_keep is odd and the home stop is to the right of the closure center.
        div(num_to_keep, 2)
      end

    omitted_indices =
      current_region_indices
      |> Enum.drop(offset)
      |> Enum.take(num_to_omit)
      |> Enum.min_max()
      |> then(fn {leftmost_omitted, rightmost_omitted} ->
        leftmost_omitted..rightmost_omitted//1
      end)

    important_indices = get_important_indices(builder)

    undesired_omissions =
      MapSet.intersection(MapSet.new(omitted_indices), MapSet.new(important_indices))

    if MapSet.size(undesired_omissions) == 0 do
      {:ok, do_omit(builder, omitted_indices)}
    else
      try_alternate_omit(builder, omitted_indices, important_indices)
    end
  end

  # Returns a sorted vector containing indices of stops that can't be omitted from the closure region.
  defp get_important_indices(builder) do
    closure_first..closure_last//1 = closure = closure_indices(builder)

    [
      closure_first,
      closure_last,
      builder.metadata.home_stop in closure and builder.metadata.home_stop,
      builder.metadata.effect == :station_closure and disrupted_stop_indices(builder)
    ]
    |> Enum.filter(& &1)
    |> List.flatten()
    |> Enum.sort()
    |> Vector.new()
  end

  defp do_omit(builder, omitted_indices) do
    label =
      omitted_indices
      |> MapSet.new(&builder.sequence[&1].id)
      |> Label.get_omission_label(builder.metadata.line, builder.metadata.branch)

    {first_omitted, last_omitted} = Enum.min_max(omitted_indices)

    builder
    |> update_in([Access.key(:sequence)], fn seq ->
      left_side = Vector.slice(seq, 0..(first_omitted - 1)//1)
      right_side = Vector.slice(seq, (last_omitted + 1)..-1//1)

      left_side +++ Vector.new([%OmittedSlot{label: label}]) +++ right_side
    end)
    |> recalculate_metadata()
  end

  # Handles rare cases where we can't omit stops from the center of the closure.
  # - First, it tries to find a segment of "omission-safe" stops to one side of the center, searching from the center outward.
  # - If there are no segments wide enough, it then tries to do the omission in two places.
  # - If it's still not possible to reduce the slots to the target amount without omitting
  #   an important stop, it gives up and returns an error tuple.
  defp try_alternate_omit(builder, original_omission, important_indices) do
    with :error <- try_side_omit(builder, original_omission, important_indices),
         :error <- try_split_omit(builder, original_omission, important_indices) do
      n = Range.size(original_omission)
      msg = "can't omit #{n} from closure region without omitting at least one important stop"

      {:error, msg}
    end
  end

  defp try_side_omit(builder, original_omission, important_indices) do
    left_try = find_safe_segment(original_omission, important_indices, :left)
    right_try = find_safe_segment(original_omission, important_indices, :right)

    case {left_try, right_try} do
      {:error, :error} ->
        :error

      {{:ok, safe_omission_left, _offset}, :error} ->
        {:ok, do_omit(builder, safe_omission_left)}

      {:error, {:ok, safe_omission_right, _offset}} ->
        {:ok, do_omit(builder, safe_omission_right)}

      both_safe ->
        both_safe
        |> Tuple.to_list()
        |> Enum.min_by(fn {:ok, _omission, offset} -> offset end)
        |> then(fn {:ok, safe_omission, _offset} -> {:ok, do_omit(builder, safe_omission)} end)
    end
  end

  defp try_split_omit(builder, original_omission, important_indices) do
    # A second omission means a second label--
    # we need to omit one additional stop to still reach the target region length.
    omit_count = 1 + Range.size(original_omission)

    closure_first = Vector.first(important_indices)
    closure_last = Vector.last(important_indices)

    center_index = center(closure_first..closure_last//1)

    # Find all safe segments, sort the longest ones first, and split those to the left
    # of the closure center from those to the right.
    {left_segments, right_segments} =
      important_indices
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [left_important, right_important] ->
        (left_important + 1)..(right_important - 1)//1
      end)
      |> Enum.reject(&(Range.size(&1) == 0))
      |> Enum.sort_by(&Range.size/1, :desc)
      |> Enum.split_with(&(center(&1) <= center_index))

    left1 = Enum.at(left_segments, 0, empty_range())
    left2 = Enum.at(left_segments, 1, empty_range())

    right1 = Enum.at(right_segments, 0, empty_range())
    right2 = Enum.at(right_segments, 1, empty_range())

    # First, try to omit from either side of the center.
    # If that's not possible, try omitting in two different places to one side of the center.
    # After that, give up!
    segment_pair =
      cond do
        Range.size(left1) + Range.size(right1) >= omit_count ->
          {Enum.reverse(left1), Enum.to_list(right1)}

        Range.size(left1) + Range.size(left2) >= omit_count ->
          {Enum.reverse(left1), Enum.reverse(left2)}

        Range.size(right1) + Range.size(right2) >= omit_count ->
          {Enum.to_list(right1), Enum.to_list(right2)}

        true ->
          :error
      end

    with {_segment1, _segment2} <- segment_pair do
      {left_omission, right_omission} = select_split_omission_indices(segment_pair, omit_count)

      # We *must* do the right omission before the left, to avoid having the indices change underneath us.
      builder =
        builder
        |> do_omit(right_omission)
        |> do_omit(left_omission)

      {:ok, builder}
    end
  end

  # Evenly pulls indices from the left and right segments until acc contains enough indices.
  defp select_split_omission_indices(segment_pair, omit_count, l_acc \\ [], r_acc \\ [])

  defp select_split_omission_indices({l, r}, omit_count, l_acc, r_acc) do
    select_split_omission_indices(l, r, omit_count, l_acc, r_acc)
  end

  defp select_split_omission_indices(_l, _r, 0, l_acc, r_acc), do: {l_acc, r_acc}

  defp select_split_omission_indices([], [h | t], n, l_acc, r_acc) do
    select_split_omission_indices([], t, n - 1, l_acc, [h | r_acc])
  end

  defp select_split_omission_indices([h | t], [], n, l_acc, r_acc) do
    select_split_omission_indices(t, [], n - 1, [h | l_acc], r_acc)
  end

  defp select_split_omission_indices([h | t], r, n, l_acc, r_acc)
       when length(l_acc) <= length(r_acc) do
    select_split_omission_indices(t, r, n - 1, [h | l_acc], r_acc)
  end

  defp select_split_omission_indices(l, [h | t], n, l_acc, r_acc) do
    select_split_omission_indices(l, t, n - 1, l_acc, [h | r_acc])
  end

  # Searches for a contiguous segment of stops, none of which are important, which
  # we can omit from the diagram.
  #
  # The search starts from the original desired omission near the center of the region
  # and moves outward, either left or right depending on the `side` argument,
  # returning either {:ok, safe_segment} or :error if none is found.
  defp find_safe_segment(original_omission, important_indices, side, offset \\ 1)

  defp find_safe_segment(original_omission, important_indices, :left, offset) do
    _l..r//1 = original_omission

    tl..tr//1 = tentative_omission = shift_range(original_omission, -offset)

    if tl <= Vector.first(important_indices) or tr >= Vector.last(important_indices) do
      :error
    else
      first_overlap =
        important_indices
        |> Vector.reverse()
        |> Aja.Enum.find(&(&1 in tentative_omission))

      case first_overlap do
        nil ->
          {:ok, tentative_omission, offset}

        i ->
          # The tentative window contains an important index. Move the window past the first important index and try again.
          find_safe_segment(original_omission, important_indices, :left, 1 + r - i)
      end
    end
  end

  defp find_safe_segment(original_omission, important_indices, :right, offset) do
    l.._r//1 = original_omission

    tl..tr//1 = tentative_omission = shift_range(original_omission, offset)

    if tl <= Vector.first(important_indices) or tr >= Vector.last(important_indices) do
      :error
    else
      first_overlap = Aja.Enum.find(important_indices, &(&1 in tentative_omission))

      case first_overlap do
        nil ->
          {:ok, tentative_omission, offset}

        i ->
          # The tentative window contains an important index. Move the window past the first important index and try again.
          find_safe_segment(original_omission, important_indices, :right, 1 + i - l)
      end
    end
  end

  defp do_add_slots(builder, 0, _), do: builder

  defp do_add_slots(builder, _greater_than_0, _)
       when vec_size(builder.left_end) == 0 and vec_size(builder.right_end) == 0 do
    # There are no more end stops available on either side.
    # This code is probably running in a test case if the stop sequence is that small.
    # Just return the builder.
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

  defp serialize_sequence(%__MODULE__{} = builder) do
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

  defp get_end_slot(meta, stops) do
    stop_ids =
      stops
      |> Vector.filter(&is_struct(&1, StopSlot))
      |> MapSet.new(& &1.id)

    label_id = Label.get_end_label_id(stop_ids, meta.line, meta.branch)

    Vector.new([%ArrowSlot{label_id: label_id}])
  end

  # Returns a sorted list of indices of the stops that are in the alert's informed entities.
  # For station closures, this is the stops that are skipped.
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

  # The closure has highest priority, so no other overlapping region can take stops from it.
  defp closure_indices(%{metadata: %{effect: :station_closure}} = builder) do
    # first = One stop before the first skipped stop, if it exists. Otherwise, the first skipped stop.
    first = clamp(builder.metadata.first_disrupted_stop - 1, vec_size(builder.sequence))

    # last = One stop past the last skipped stop, if it exists. Otherwise, the last skipped stop.
    last = clamp(builder.metadata.last_disrupted_stop + 1, vec_size(builder.sequence))

    first..last//1
  end

  defp closure_indices(%{metadata: %{effect: continuous} = metadata})
       when continuous in [:shuttle, :suspension] do
    metadata.first_disrupted_stop..metadata.last_disrupted_stop//1
  end

  # The gap region has second highest priority and by its definition doesn't overlap with the closure region.
  defp gap_indices(builder) do
    home_stop = builder.metadata.home_stop

    closure_left..closure_right//1 = closure_indices(builder)

    cond do
      home_stop < closure_left -> (home_stop + 1)..(closure_left - 1)//1
      home_stop > closure_right -> (closure_right + 1)..(home_stop - 1)//1
      true -> empty_range()
    end
  end

  # The current location region can be subsumed by the closure and the gap regions.
  defp current_location_indices(builder) do
    current_location_region = MapSet.new(current_location_ideal_indices(builder))

    gap_region = MapSet.new(gap_indices(builder))
    closure_region = MapSet.new(closure_indices(builder))

    current_location_region
    |> MapSet.difference(MapSet.union(gap_region, closure_region))
    |> Enum.min_max(fn -> :its_empty end)
    |> case do
      {left, right} -> left..right//1
      :its_empty -> empty_range()
    end
  end

  # Indices of the current location region if none were taken by other higher-precedence regions.
  defp current_location_ideal_indices(builder) do
    home_stop = builder.metadata.home_stop

    size = vec_size(builder.sequence)

    clamp(home_stop - 1, size)..clamp(home_stop + 1, size)//1
  end

  # (Just left of center if length is even.)
  defp center(l..r//1) when r >= l do
    l + div(r - l, 2)
  end

  # Adjusts an index to be within the bounds of the stop sequence.
  defp clamp(index, _sequence_size) when index < 0, do: 0
  defp clamp(index, sequence_size) when index >= sequence_size, do: sequence_size - 1
  defp clamp(index, _sequence_size), do: index

  # Returns a range of size 0.
  # When used to slice an enumerable, it returns the whole enumerable (from index 0 to index -1, the last element).
  # When we upgrade to Elixir 1.14, this can be replaced with just `..`.
  # https://hexdocs.pm/elixir/Kernel.html#../0
  defp empty_range, do: 0..-1//1

  # Shifts a range by the given number of steps.
  # When we upgrade to Elixir 1.14, this can be replaced with `Range.shift/2`.
  def shift_range(first..last//step, steps_to_shift)
      when is_integer(first) and is_integer(last) and is_integer(step) and
             is_integer(steps_to_shift) do
    Range.new(first + steps_to_shift * step, last + steps_to_shift * step, step)
  end
end
