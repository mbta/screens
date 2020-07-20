defmodule Screens.Config.Solari.Section.Layout.RouteConfig.RouteDescriptor do
  @moduledoc false

  @type t :: {String.t(), direction_id}

  @type direction_id :: 0 | 1

  @spec from_json(map()) :: t()
  def from_json(%{"route" => route, "direction_id" => direction_id}) do
    {route, direction_id}
  end

  @spec to_json(t()) :: map()
  def to_json({route, direction_id}) do
    %{"route" => route, "direction_id" => direction_id}
  end
end
