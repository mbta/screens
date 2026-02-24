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
          route: Route.id() | nil,
          route_type: non_neg_integer() | nil,
          stop: Stop.t() | nil
        }

  @spec whole_route?(t()) :: boolean
  def whole_route?(ie) do
    match?(
      %{route: route_id, direction_id: nil, stop: nil}
      when not is_nil(route_id),
      ie
    )
  end

  @spec whole_direction?(t()) :: boolean
  def whole_direction?(ie) do
    match?(
      %{route: route_id, direction_id: direction_id, stop: nil}
      when not is_nil(route_id) and not is_nil(direction_id),
      ie
    )
  end

  @spec parent_station?(t()) :: boolean
  def parent_station?(%__MODULE__{stop: %Stop{id: "place-" <> _}}), do: true
  def parent_station?(_), do: false

  @spec present_alert_for_route?(t(), Route.id(), Trip.direction() | nil) :: boolean()
  def present_alert_for_route?(
        %__MODULE__{route: entity_route_id, direction_id: entity_direction},
        route_id,
        direction_id
      )
      when entity_route_id == route_id do
    case entity_direction do
      ^direction_id -> true
      nil -> true
      _ -> false
    end
  end

  def present_alert_for_route?(_, _, _), do: false

  @spec filter_duplicate_and_nil_stops([t()]) :: [t()]
  @doc """
  Returns a deduplicated list of informed entities based on stop ID.
  Removes any Informed Entities with nil stops.
  """
  def filter_duplicate_and_nil_stops(entities) do
    entities
    |> Enum.uniq_by(fn
      %__MODULE__{stop: %Stop{id: id}} -> id
      _ -> nil
    end)
    |> Enum.filter(fn id -> not is_nil(id) end)
  end
end
