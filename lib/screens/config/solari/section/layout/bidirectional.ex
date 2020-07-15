defmodule Screens.Config.Solari.Section.Layout.Bidirectional do
  alias Screens.Config.Solari.Section.Layout.RouteConfig

  @type t :: %__MODULE__{
          routes: RouteConfig.t()
        }

  defstruct routes: RouteConfig.from_json(:default)

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    routes = Map.get(json, "routes", :default)
    %__MODULE__{routes: RouteConfig.from_json(routes)}
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{routes: routes}) do
    %{"routes" => RouteConfig.to_json(routes)}
  end
end
