defmodule Screens.Config.Solari.Section.Layout.RouteConfig do
  alias Screens.Config.Solari.Section.Layout.RouteConfig.RouteDescriptor

  @type t :: %__MODULE__{
          action: :exclude | :include,
          route_list: list(RouteDescriptor.t())
        }

  @default_action :exclude

  defstruct action: @default_action,
            route_list: []

  @spec from_json(map() | :default) :: t()
  def from_json(%{"action" => action, "route_list" => route_list}) when is_list(route_list) do
    %__MODULE__{
      action: action_from_json(action),
      route_list: Enum.map(route_list, &RouteDescriptor.from_json/1)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{action: action, route_list: route_list}) do
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
