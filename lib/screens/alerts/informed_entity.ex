defmodule Screens.Alerts.InformedEntity do
  @moduledoc """
  Functions to query alert informed entities.
  """

  alias Screens.Alerts.Alert

  @type t :: Alert.informed_entity()

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
end
