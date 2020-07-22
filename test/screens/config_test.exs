defmodule Screens.ConfigTest do
  use ExUnit.Case, async: true

  alias Screens.Config
  alias Screens.Config.State.LocalFetch

  @test_config_path Path.join(~w[#{File.cwd!()} test fixtures config.json])

  def fetch_config(_context) do
    {:ok, config} = LocalFetch.fetch_config(@test_config_path)
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
