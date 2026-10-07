defmodule Screens.TestSupport.ScreenConfigBuilder do
  @moduledoc """
  Helpers for building screen config fixtures in tests.

  Provides screen structs and JSON payloads for Postgres-backed configuration tests.
  """

  alias ScreensConfig.Screen

  def screen_config_json(app_id), do: app_id |> screen_config() |> Screen.to_json()

  def screen_config(app_id, opts \\ []) do
    %{
      "app_id" => Atom.to_string(app_id),
      "app_params" => minimal_app_params(app_id),
      "device_id" => "test-device",
      "name" => "test-screen",
      "vendor" => opts |> Keyword.get(:vendor, :gds) |> Atom.to_string()
    }
    |> Screen.from_json()
  end

  defp minimal_app_params(:dup_v2) do
    %{
      "header" => %{"stop_name" => "Test Stop"},
      "primary_departures" => %{"sections" => []},
      "secondary_departures" => %{"sections" => []},
      "alerts" => %{"stop_id" => "place-test"}
    }
  end

  defp minimal_app_params(:busway_v2) do
    %{
      "header" => %{"stop_name" => "Test Stop"},
      "departures" => %{"sections" => []}
    }
  end

  defp minimal_app_params(:bus_eink_v2) do
    %{
      "alerts" => %{"stop_ids" => ["place-test"]},
      "departures" => %{"sections" => []},
      "footer" => %{"stop_id" => "place-test"},
      "header" => %{"stop_name" => "Test Stop"}
    }
  end

  def normalize_json(map), do: map |> Jason.encode!() |> Jason.decode!()
end
