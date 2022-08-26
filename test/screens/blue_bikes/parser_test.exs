defmodule Screens.BlueBikes.ParserTest do
  import Screens.BlueBikes.Parser

  alias Screens.BlueBikes
  alias Screens.BlueBikes.StationStatus

  use ExUnit.Case, async: true

  setup do
    info_stations = [
      station_info("1", "station 1"),
      station_info("2", "station 2"),
      station_info("3", "station 3"),
      station_info("x", "station missing from status")
    ]

    status_stations = [
      station_status("1", num_bikes_available: 3, num_docks_available: 5),
      station_status("2", valet_active?: true),
      station_status("3", status: "out_of_service"),
      station_status("y")
    ]

    information = %{
      "last_updated" => 1234,
      "data" => %{"stations" => info_stations}
    }

    status = %{
      "last_updated" => 5678,
      "data" => %{"stations" => status_stations}
    }

    %{information: information, status: status, x_information: nil, x_status: nil}
  end

  defp station_info(id, name), do: %{"station_id" => id, "name" => name}

  defp station_status(id, fields \\ []) do
    map = %{
      "station_id" => id,
      "num_bikes_available" => fields[:num_bikes_available] || 0,
      "num_docks_available" => fields[:num_docks_available] || 0,
      "station_status" => fields[:status] || "active"
    }

    map =
      if fields[:valet_active?] do
        Map.put(map, "valet", %{"active" => true})
      else
        map
      end

    map
  end

  describe "parse/2" do
    test "parses information and status, omitting any station IDs missing from either", %{
      information: information,
      status: status
    } do
      expected_data = %BlueBikes{
        stations_by_id: %{
          "1" => %StationStatus{
            name: "station 1",
            status: {:normal, %{num_bikes_available: 3, num_docks_available: 5}}
          },
          "2" => %StationStatus{name: "station 2", status: :valet},
          "3" => %StationStatus{name: "station 3", status: :out_of_service}
        }
      }

      expected_information_last_updated = 1234
      expected_status_last_updated = 5678

      expected =
        {:ok, expected_data, expected_information_last_updated, expected_status_last_updated}

      assert expected == parse(information, status)
    end

    test "returns :error if either file fails to parse", context do
      assert :error = parse(context.x_information, context.status)
      assert :error = parse(context.information, context.x_status)
    end
  end
end
