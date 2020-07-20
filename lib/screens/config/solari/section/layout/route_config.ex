defmodule Screens.Config.Solari.Section.Layout.RouteConfig do
  @moduledoc false

  alias Screens.Config.Solari.Section.Layout.RouteConfig.RouteDescriptor

  @type t :: {:exclude | :include, list(RouteDescriptor.t())}

  @default_action :exclude

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    action = Map.get(json, "action", :default)
    route_list = Map.get(json, "route_list", [])
    route_list = if is_list(route_list), do: route_list, else: []

    {
      action_from_json(action),
      Enum.map(route_list, &RouteDescriptor.from_json/1)
    }
  end

  def from_json(:default) do
    {@default_action, []}
  end

  @spec to_json(t()) :: map()
  def to_json({action, route_list}) do
    %{
      "action" => action_to_json(action),
      "route_list" => Enum.map(route_list, &RouteDescriptor.to_json/1)
    }
  end

  for action <- ~w[exclude include]a do
    action_string = Atom.to_string(action)

    defp action_from_json(unquote(action_string)) do
      unquote(action)
    end

    defp action_to_json(unquote(action)) do
      unquote(action_string)
    end
  end

  defp action_from_json(_) do
    @default_action
  end
end
