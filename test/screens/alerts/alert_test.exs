defmodule Screens.Alerts.AlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Alerts.InformedEntity
  alias Screens.Facilities.Facility
  alias Screens.Stops.Stop

  import Screens.TestSupport.InformedEntityBuilder

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
        {
          :ok,
          %{"data" => [%{"id" => "999", "type" => "alert", "attributes" => @minimal_attributes}]}
        }
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
          %InformedEntity{
            stop: nil,
            route: "1",
            direction_id: nil,
            route_type: nil,
            activities: ~w[board exit ride]a,
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
           "data" => [%{"id" => "999", "type" => "alert", "attributes" => attributes}],
           "included" => [facility_data]
         }}
      end

      {:ok, [alert]} = Alert.fetch([], get_json_fn)

      assert %Alert{
               informed_entities: [
                 %InformedEntity{facility: %Facility{id: "870", type: :elevator}}
               ]
             } =
               alert
    end

    test "combine informed entities by direction_id" do
      attributes = %{
        @minimal_attributes
        | "informed_entity" => [
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "1",
              "stop" => "stop_one",
              "direction_id" => 1
            },
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "2",
              "stop" => "stop_two",
              "direction_id" => 1
            },
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "2",
              "stop" => "stop_two",
              "direction_id" => 0
            }
          ]
      }

      get_json_fn = fn "alerts", %{"filter[route]" => "1"} ->
        {
          :ok,
          %{
            "data" => [%{"id" => "999", "type" => "alert", "attributes" => attributes}],
            "included" => [
              %{
                "id" => "stop_one",
                "type" => "stop",
                "attributes" => %{
                  "name" => "Stop One",
                  "location_type" => 0,
                  "platform_code" => nil,
                  "platform_name" => nil,
                  "vehicle_type" => nil
                },
                "relationships" => %{}
              },
              %{
                "id" => "stop_two",
                "type" => "stop",
                "attributes" => %{
                  "name" => "Stop Two",
                  "location_type" => 0,
                  "platform_code" => nil,
                  "platform_name" => nil,
                  "vehicle_type" => nil
                },
                "relationships" => %{}
              }
            ]
          }
        }
      end

      {:ok, [alert]} = Alert.fetch([route_ids: ["1"]], get_json_fn)

      assert %Alert{
               informed_entities: [
                 %InformedEntity{
                   stop: %Stop{id: "stop_one"},
                   route: "1",
                   direction_id: 1,
                   route_type: nil,
                   activities: ~w[board exit ride]a,
                   facility: nil
                 },
                 %InformedEntity{
                   stop: %Stop{id: "stop_two"},
                   route: "2",
                   direction_id: nil,
                   route_type: nil,
                   activities: ~w[board exit ride]a,
                   facility: nil
                 }
               ]
             } = alert
    end

    test "combine informed entities by direction_id while handling nil direction_ids" do
      attributes = %{
        @minimal_attributes
        | "informed_entity" => [
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "1",
              "stop" => "stop_one",
              "direction_id" => nil
            },
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "1",
              "stop" => "stop_one",
              "direction_id" => 0
            },
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "2",
              "stop" => "stop_two",
              "direction_id" => nil
            },
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "2",
              "stop" => "stop_two",
              "direction_id" => 1
            },
            %{
              "activities" => ~w[BOARD EXIT RIDE],
              "route" => "2",
              "stop" => "stop_two",
              "direction_id" => 0
            }
          ]
      }

      get_json_fn = fn "alerts", %{"filter[route]" => "1"} ->
        {
          :ok,
          %{
            "data" => [%{"id" => "999", "type" => "alert", "attributes" => attributes}],
            "included" => [
              %{
                "id" => "stop_one",
                "type" => "stop",
                "attributes" => %{
                  "name" => "Stop One",
                  "platform_name" => "Stop One Platform",
                  "location_type" => 0,
                  "platform_code" => nil,
                  "vehicle_type" => nil
                },
                "relationships" => %{}
              },
              %{
                "id" => "stop_two",
                "type" => "stop",
                "attributes" => %{
                  "name" => "Stop Two",
                  "location_type" => 0,
                  "platform_code" => nil,
                  "platform_name" => nil,
                  "vehicle_type" => nil
                },
                "relationships" => %{}
              }
            ]
          }
        }
      end

      {:ok, [alert]} = Alert.fetch([route_ids: ["1"]], get_json_fn)

      assert %Alert{
               informed_entities: [
                 %InformedEntity{
                   stop: %Stop{id: "stop_one", platform_name: "Stop One Platform"},
                   route: "1",
                   direction_id: nil,
                   route_type: nil,
                   activities: ~w[board exit ride]a,
                   facility: nil
                 },
                 %InformedEntity{
                   stop: %Stop{id: "stop_two"},
                   route: "2",
                   direction_id: nil,
                   route_type: nil,
                   activities: ~w[board exit ride]a,
                   facility: nil
                 }
               ]
             } = alert
    end
  end

  describe "fetch_by_stop_and_route/3" do
    defp alert_json(id), do: %{"id" => id, "type" => "alert", "attributes" => @minimal_attributes}

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

  describe "direction_id/1" do
    test "returns nil when all informed parent stations are affected in both directions" do
      alert = %Alert{
        informed_entities: [
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: 0,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "12345"}
          },
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: nil,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "place-a"}
          }
        ]
      }

      assert Alert.direction_id(alert) == nil
    end

    test "returns nil when informed parent stations have a mix of directions" do
      # Typical disruption with "endpoints" where only one direction of service is affected and
      # a "middle" where both directions are
      alert = %Alert{
        informed_entities: [
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: 0,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "place-a"}
          },
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: nil,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "place-b"}
          },
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: 1,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "place-c"}
          }
        ]
      }

      assert Alert.direction_id(alert) == nil
    end

    test "returns nil when informed parent stations all have different non-nil directions" do
      # Scenario where the disruption has "endpoints" but they're adjacent stations
      alert = %Alert{
        informed_entities: [
          %{
            activities: ~w[board exit ride]a,
            direction_id: 0,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: "place-a"
          },
          %{
            activities: ~w[board exit ride]a,
            direction_id: 1,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: "place-b"
          }
        ]
      }

      assert Alert.direction_id(alert) == nil
    end

    test "returns the direction ID when all parent stations are affected in the same direction" do
      alert = %Alert{
        informed_entities: [
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: nil,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "12345"}
          },
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: 0,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "place-a"}
          },
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: 0,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: %Stop{id: "place-b"}
          }
        ]
      }

      assert Alert.direction_id(alert) == 0
    end

    test "returns nil when there are no specific affected stops and no affected direction" do
      alert = %Alert{
        informed_entities: [
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: nil,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: nil
          }
        ]
      }

      assert Alert.direction_id(alert) == nil
    end

    test "returns the direction ID when a whole direction is affected" do
      alert = %Alert{
        informed_entities: [
          %InformedEntity{
            activities: ~w[board exit ride]a,
            direction_id: 1,
            facility: nil,
            route: "1",
            route_type: nil,
            stop: nil
          }
        ]
      }

      assert Alert.direction_id(alert) == 1
    end
  end

  describe "consolidate_route_delays/1" do
    test "keeps the highest severity delay for each route" do
      red_alert_1 = %Alert{
        id: "1",
        effect: :delay,
        severity: 3,
        informed_entities: [ie(route: "Red")]
      }

      red_alert_2 = %Alert{
        id: "2",
        effect: :delay,
        severity: 5,
        informed_entities: [ie(route: "Red")]
      }

      red_alert_3 = %Alert{
        id: "3",
        effect: :delay,
        severity: 4,
        informed_entities: [ie(route: "Red")]
      }

      orange_alert_1 = %Alert{
        id: "4",
        effect: :delay,
        severity: 2,
        informed_entities: [ie(route: "Orange")]
      }

      orange_alert_2 = %Alert{
        id: "5",
        effect: :delay,
        severity: 4,
        informed_entities: [ie(route: "Orange")]
      }

      blue_alert = %Alert{
        id: "6",
        effect: :delay,
        severity: 1,
        informed_entities: [ie(route: "Blue")]
      }

      result =
        Alert.consolidate_whole_route_delays([
          red_alert_1,
          red_alert_2,
          red_alert_3,
          orange_alert_1,
          orange_alert_2,
          blue_alert
        ])

      assert Enum.member?(result, red_alert_2)
      assert Enum.member?(result, orange_alert_2)
      assert Enum.member?(result, blue_alert)
      assert length(result) == 3
    end

    test "properly consolidates a multi-branch GL delay" do
      gl_ies = [
        ie(route: "Green-B"),
        ie(route: "Green-C"),
        ie(route: "Green-D"),
        ie(route: "Green-E")
      ]

      alerts = [
        %Alert{
          informed_entities: gl_ies,
          id: "1",
          effect: :delay,
          severity: 3
        },
        %Alert{
          informed_entities: gl_ies,
          id: "2",
          effect: :delay,
          severity: 5
        },
        %Alert{
          informed_entities: gl_ies,
          id: "3",
          effect: :delay,
          severity: 2
        }
      ]

      expected = [
        %Alert{
          informed_entities: gl_ies,
          id: "2",
          effect: :delay,
          severity: 5
        }
      ]

      assert expected == Alert.consolidate_whole_route_delays(alerts)
    end
  end
end
