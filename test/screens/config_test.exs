defmodule Screens.ConfigTest do
  use ExUnit.Case, async: true

  alias Screens.Config
  alias Screens.Config.Fetch

  def fetch_config(_context) do
    {:ok, file_contents, _} = Fetch.fetch_config(nil)
    {:ok, parsed} = Jason.decode(file_contents)
    config = Config.from_json(parsed)

    {:ok, %{config: config}}
  end

  describe "config" do
    setup :fetch_config

    test "is unchanged when converted to JSON and back again", %{config: config} do
      roundtrip =
        config |> Config.to_json() |> Jason.encode!() |> Jason.decode!() |> Config.from_json()

      assert config == roundtrip
    end
  end
end
