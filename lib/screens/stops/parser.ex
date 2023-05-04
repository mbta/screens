defmodule Screens.Stops.Parser do
  @moduledoc false

  def parse_stop(%{
        "id" => id,
        "attributes" => %{"name" => name, "platform_code" => platform_code}
      }) do
    %Screens.Stops.Stop{
      id: id,
      name: name,
      platform_code: platform_code
    }
  end
end
