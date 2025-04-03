defmodule Screens.Alerts.AlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Facilities.Facility

  # Minimal valid attributes by V3 API resource definitions.
  @minimal_attributes %{
    "active_period" => [%{"start" => "2017-08-14T14:54:01-04:00", "end" => nil}],
    "banner" => nil,
    "cause" => "ACCIDENT",
    "created_at" => "2017-08-14T14:54:01-04:00",
    "description" => nil,
    "duration_certainty" => "UNKNOWN",
    "effect" => "DELAY",
    "header" => "Route 1 experiencing delays up to 20 minutes due to an accident.",
    "image" => nil,
    "image_alternative_text" => nil,
    "informed_entity" => [%{"activities" => ~w[BOARD EXIT RIDE], "route" => "1"}],
    "lifecycle" => "ONGOING",
    "service_effect" => "Route 1 delay",
    "severity" => 5,
    "short_header" => "Route 1 delayed up to 20 minutes due to an accident.",
    "timeframe" => nil,
    "updated_at" => "2017-08-14T14:54:01-04:00",
    "url" => nil
  }

  describe "fetch/2" do
    test "fetches and parses alerts" do
      get_json_fn = fn "alerts", %{"filter[route]" => "1"} ->
        {:ok, %{"data" => [%{"id" => "999", "attributes" => @minimal_attributes}]}}
      end

      expected = %Alert{
        active_period: [{~U[2017-08-14 18:54:01Z], nil}],
        cause: :accident,
        created_at: ~U[2017-08-14 18:54:01Z],
        description: nil,
        effect: :delay,
        header: "Route 1 experiencing delays up to 20 minutes due to an accident.",
        id: "999",
        informed_entities: [
          %{
            stop: nil,
            route: "1",
            direction_id: nil,
            route_type: nil,
            activities: ~w[BOARD EXIT RIDE],
            facility: nil
          }
        ],
        lifecycle: "ONGOING",
        severity: 5,
        timeframe: nil,
        updated_at: ~U[2017-08-14 18:54:01Z],
        url: nil
      }

      assert Alert.fetch([route_ids: ["1"]], get_json_fn) == {:ok, [expected]}
    end

    test "parses related facilities" do
      attributes = %{
        @minimal_attributes
        | "informed_entity" => [%{"activities" => ~w[USING_WHEELCHAIR], "facility" => "870"}]
      }

      facility_data = %{
        "id" => "870",
        "type" => "facility",
        "attributes" => %{
          "latitude" => nil,
          "longitude" => nil,
          "long_name" => "longname",
          "short_name" => "shortname",
          "properties" => [],
          "type" => "ELEVATOR"
        },
        "relationships" => %{
          "stop" => %{"data" => %{"id" => "place-test", "type" => "stop"}}
        }
      }

      get_json_fn = fn "alerts", %{} ->
        {:ok,
         %{
           "data" => [%{"id" => "999", "attributes" => attributes}],
           "included" => [facility_data]
         }}
      end

      {:ok, [alert]} = Alert.fetch([], get_json_fn)

      assert %Alert{informed_entities: [%{facility: %Facility{id: "870", type: :elevator}}]} =
               alert
    end
  end

  describe "fetch_by_stop_and_route/3" do
    defp alert_json(id), do: %{"id" => id, "attributes" => @minimal_attributes}

    setup do
      stop_based_alerts = [alert_json("1"), alert_json("2"), alert_json("3")]
      route_based_alerts = [alert_json("4"), alert_json("3"), alert_json("5")]

      stop_ids = ~w[1265 1266 10413 11413 17411]
      route_ids = ~w[22 29 44]

      stop_ids_param = Enum.join(stop_ids, ",")
      route_ids_param = Enum.join(route_ids, ",")

      %{
        stop_ids: ~w[1265 1266 10413 11413 17411],
        route_ids: ~w[22 29 44],
        get_json_fn: fn
          _, %{"filter[stop]" => ^stop_ids_param, "filter[route]" => ^route_ids_param} ->
            {:ok, %{"data" => stop_based_alerts}}

          _, %{"filter[route]" => ^route_ids_param} ->
            {:ok, %{"data" => route_based_alerts}}
        end,
        x_get_json_fn1: fn
          _, %{"filter[stop]" => ^stop_ids_param, "filter[route]" => ^route_ids_param} -> :error
          _, %{"filter[route]" => ^route_ids_param} -> {:ok, %{"data" => route_based_alerts}}
        end,
        x_get_json_fn2: fn
          _, %{"filter[stop]" => ^stop_ids_param, "filter[route]" => ^route_ids_param} ->
            {:ok, %{"data" => stop_based_alerts}}

          _, %{"filter[route]" => ^route_ids_param} ->
            :error
        end
      }
    end

    test "returns {:ok, merged_alerts} if fetch function succeeds in both cases", context do
      %{
        stop_ids: stop_ids,
        route_ids: route_ids,
        get_json_fn: get_json_fn
      } = context

      assert {:ok,
              [
                %Alert{id: "1"},
                %Alert{id: "2"},
                %Alert{id: "3"},
                %Alert{id: "4"},
                %Alert{id: "5"}
              ]} = Alert.fetch_by_stop_and_route(stop_ids, route_ids, get_json_fn)
    end

    test "returns :error if fetch function returns :error", context do
      %{
        stop_ids: stop_ids,
        route_ids: route_ids,
        x_get_json_fn1: x_get_json_fn1,
        x_get_json_fn2: x_get_json_fn2
      } = context

      assert :error == Alert.fetch_by_stop_and_route(stop_ids, route_ids, x_get_json_fn1)
      assert :error == Alert.fetch_by_stop_and_route(stop_ids, route_ids, x_get_json_fn2)
    end
  end
end
