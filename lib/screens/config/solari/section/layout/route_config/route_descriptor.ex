defmodule Screens.Config.Solari.Section.Layout.RouteConfig.RouteDescriptor do
  @type t :: %__MODULE__{
          route: String.t(),
          direction_id: direction_id
        }

  @type direction_id :: 0 | 1

  defstruct route: "",
            direction_id: 0

  @spec from_json(map()) :: t()
  def from_json(%{"route" => route, "direction_id" => direction_id}) do
    %__MODULE__{route: route, direction_id: direction_id}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{route: route, direction_id: direction_id}) do
    %{"route" => route, "direction_id" => direction_id}
  end
end
