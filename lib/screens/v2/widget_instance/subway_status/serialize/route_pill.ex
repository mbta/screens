defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize.RoutePill do
  @moduledoc """
  Route pill serialization for the Subway Status widget.
  """

  alias Screens.V2.WidgetInstance.SubwayStatus

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  @spec serialize_route_pill(String.t()) :: SubwayStatus.route_pill()
  def serialize_route_pill(route_id) do
    case route_id do
      "Blue" -> %{type: :text, color: :blue, text: "BL"}
      "Orange" -> %{type: :text, color: :orange, text: "OL"}
      "Red" -> %{type: :text, color: :red, text: "RL"}
      _ -> %{type: :text, color: :green, text: "GL"}
    end
  end

  @spec serialize_gl_pill_with_branches(list(String.t())) :: SubwayStatus.route_pill()
  def serialize_gl_pill_with_branches(route_ids) do
    branches =
      route_ids
      |> Enum.filter(&(&1 in @green_line_branches))
      |> Enum.map(fn "Green-" <> branch ->
        branch |> String.downcase() |> String.to_existing_atom()
      end)

    %{type: :text, color: :green, text: "GL", branches: branches}
  end

  @spec serialize_rl_mattapan_pill :: SubwayStatus.route_pill()
  def serialize_rl_mattapan_pill do
    %{type: :text, color: :red, text: "RL", branches: [:m]}
  end
end
