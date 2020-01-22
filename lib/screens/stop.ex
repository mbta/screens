defmodule Screens.Stop do
  @moduledoc false

  def get_name_by_id(stop_id) do
    with {:ok, result} <- Screens.V3Api.get_json("stops/" <> stop_id),
         %{"data" => %{"attributes" => %{"name" => stop_name}}} <- result do
      stop_name
    end
  end
end
