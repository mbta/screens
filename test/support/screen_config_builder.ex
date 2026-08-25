defmodule Screens.TestSupport.ScreenConfigBuilder do
  @moduledoc """
  Helpers for building screen config fixtures in tests.

  Provides normalized and legacy-shaped config payloads used by tests that
  exercise screen config parsing, loading, and compatibility behavior.

  During post_config_migration_cleanup, this file can be simplified to remove the legacy config helpers.
  """

  alias ScreensConfig.Screen

  def screen_config_json(app_id), do: app_id |> screen_config() |> Screen.to_json()

  def screen_config(app_id) do
    %{
      "app_id" => Atom.to_string(app_id),
      "app_params" => minimal_app_params(app_id),
      "device_id" => "test-device",
      "name" => "test-screen",
      "vendor" => "gds"
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

  def legacy_config(screen_dup_config, screen_busway_config) do
    %{
      "screens" => %{
        "dup_1" => screen_dup_config,
        "busway_1" => screen_busway_config
      }
    }
  end

  def legacy_config_dup_only do
    dup_old_config =
      screen_config_json(:dup_v2)
      |> Map.put("app_id", "dup_old")

    %{
      "screens" => %{
        "dup_1" => dup_old_config
      }
    }
  end

  def normalize_json(map), do: map |> Jason.encode!() |> Jason.decode!()
end
