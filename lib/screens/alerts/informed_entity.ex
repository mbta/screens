defmodule Screens.Alerts.InformedEntity do
  @moduledoc """
  Functions to query alert informed entities.
  """

  alias Screens.Alerts.Alert
  alias Screens.Facilities.Facility
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip

  defstruct activities: [],
            direction_id: nil,
            facility: nil,
            route: nil,
            route_type: nil,
            stop: nil

  @type t :: %__MODULE__{
          activities: nonempty_list(Alert.activity()),
          direction_id: Trip.direction() | nil,
          facility: Facility.t() | nil,
          route: Route.t() | nil,
          route_type: non_neg_integer() | nil,
          stop: Stop.t() | nil
        }

  @spec whole_route?(t()) :: boolean
  def whole_route?(ie) do
    match?(%{route: %Route{id: _route_id}, direction_id: nil, stop: nil}, ie)
  end

  @spec whole_direction?(t()) :: boolean
  def whole_direction?(ie) do
    match?(
      %{route: %Route{id: _route_id}, direction_id: direction_id, stop: nil}
      when not is_nil(direction_id),
      ie
    )
  end

  @spec parent_station?(t()) :: boolean
  def parent_station?(%__MODULE__{stop: %Stop{id: "place-" <> _}}), do: true
  def parent_station?(_), do: false

  @doc """
  Returns a deduplicated list of informed entities based on stop ID.
  Removes any Informed Entities with nil stops.
  """
  @spec uniq_by_stop([t()]) :: [t()]
  def uniq_by_stop(entities) do
    entities
    |> Enum.uniq_by(fn
      %__MODULE__{stop: %Stop{id: id}} -> id
      _ -> nil
    end)
    |> Enum.filter(fn ie -> not is_nil(ie.stop) end)
  end

  @spec boarding_platforms_from_entities([t()]) :: [Stop.t()]
  def boarding_platforms_from_entities(informed_parent_stations) do
    informed_parent_stations
    |> Enum.flat_map(
      &case &1.stop.child_stops do
        nil -> []
        child_stops -> child_stops
      end
    )
    |> Stop.filter_subway_platforms()
  end
end
