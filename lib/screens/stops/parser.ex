defmodule Screens.Stops.Parser do
  @moduledoc false

  def parse_stop(%{
        "id" => id,
        "attributes" => %{
          "name" => name,
          "location_type" => location_type,
          "platform_code" => platform_code,
          "platform_name" => platform_name
        }
      }) do
    %Screens.Stops.Stop{
      id: id,
      name: name,
      location_type: location_type,
      platform_code: platform_code,
      platform_name: platform_name
    }
  end
end
