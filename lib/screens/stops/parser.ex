defmodule Screens.Stops.Parser do
  @moduledoc false

  def parse_stop(%{"id" => id, "attributes" => %{"name" => name}}) do
    %Screens.Stops.Stop{
      id: id,
      name: name
    }
  end
end
