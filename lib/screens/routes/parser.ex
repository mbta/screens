defmodule Screens.Routes.Parser do
  @moduledoc false

  def parse_route(%{"id" => id, "attributes" => %{"short_name" => short_name}}) do
    %Screens.Routes.Route{
      id: id,
      short_name: short_name
    }
  end
end
