defmodule Screens.Facilities.FacilityTest do
  use ExUnit.Case, async: true

  alias Screens.Stops.Stop
  alias Screens.Facilities.Facility

  @data %{
    "id" => "954",
    "type" => "facility",
    "attributes" => %{
      "latitude" => -71.194994,
      "longitude" => 42.316115,
      "long_name" => "SHAWMUT - Ashmont Bound Platform to Lobby",
      "short_name" => "Ashmont platform to lobby",
      "properties" => [
        %{"name" => "alternate-service-text", "value" => "some text"},
        %{"name" => "excludes-stop", "value" => 70091}
      ],
      "type" => "ELEVATOR"
    },
    "relationships" => %{
      "stop" => %{"data" => %{"id" => "place-smmnl", "type" => "stop"}}
    }
  }

  @included [
    %{
      "id" => "place-smmnl",
      "type" => "stop",
      "attributes" => %{
        "name" => "Shawmut",
        "location_type" => 1,
        "platform_code" => nil,
        "platform_name" => nil,
        "vehicle_type" => 1
      },
      "relationships" => %{}
    }
  ]

  @expected %Facility{
    id: "954",
    excludes_stop_ids: ["70091"],
    latitude: -71.194994,
    longitude: 42.316115,
    long_name: "SHAWMUT - Ashmont Bound Platform to Lobby",
    short_name: "Ashmont platform to lobby",
    stop: %Stop{
      id: "place-smmnl",
      child_stops: :unloaded,
      connecting_stops: :unloaded,
      location_type: 1,
      name: "Shawmut",
      vehicle_type: :subway
    },
    type: :elevator
  }

  defp build(fields) do
    struct!(
      %Facility{id: "test", long_name: "L", short_name: "S", stop: :unloaded, type: :elevator},
      fields
    )
  end

  describe "fetch/2" do
    test "fetches and parses facilities" do
      get_json_fn = fn "facilities",
                       %{
                         "filter[stop]" => "place-smmnl",
                         "filter[type]" => "ELEVATOR",
                         "include" => "stop"
                       } ->
        {:ok, %{"data" => [@data], "included" => @included}}
      end

      assert Facility.fetch([stop_ids: ["place-smmnl"], types: [:elevator]], get_json_fn) ==
               {:ok, [@expected]}
    end
  end

  describe "fetch_by_id/2" do
    test "fetches and parses a facility by ID" do
      get_json_fn = fn "facilities/954", %{"include" => "stop"} ->
        {:ok, %{"data" => @data, "included" => @included}}
      end

      assert Facility.fetch_by_id("954", get_json_fn) == {:ok, @expected}
    end
  end

  describe "served_stop_ids/1" do
    test "determines which child stop IDs the facility serves based on its excluded stop IDs" do
      facility =
        build(
          excludes_stop_ids: ~w[2 3],
          stop: %Stop{
            location_type: 1,
            child_stops: [%Stop{id: "1"}, %Stop{id: "2"}, %Stop{id: "3"}, %Stop{id: "4"}]
          }
        )

      assert Facility.served_stop_ids(facility) == ~w[1 4]
    end
  end
end
