defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlertTest do
  use ExUnit.Case, async: true

  import Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ReconstructedAlert, as: ReconstructedAlertWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.{Busway, PreFare}

  import Screens.TestSupport.InformedEntityBuilder

  describe "reconstructed_alert_instances/5" do
    setup do
      stop_id = "place-ogmnl"

      app = PreFare

      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(app, %{reconstructed_alert_widget: %ScreensConfig.Alerts{stop_id: stop_id}})
        })

      bad_config = struct(Screen, %{app_params: struct(Busway)})

      routes_at_stop = [
        %{
          route_id: "Orange",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :subways
        }
      ]

      happening_now_active_period = [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]

      oak_grove_sb = %Stop{
        id: "70036",
        name: "Oak Grove - Southbound",
        platform_name: "Southbound",
        location_type: 0,
        vehicle_type: :subway
      }

      oak_grove_nb = %Stop{
        id: "70035",
        name: "Oak Grove - Northbound",
        platform_name: "Northbound",
        location_type: 0,
        vehicle_type: :subway
      }

      oak_grove_parent = %Stop{
        id: "place-ogmnl",
        name: "Oak Grove",
        location_type: 1,
        child_stops: [oak_grove_nb, oak_grove_sb]
      }

      malden_center_sb = %Stop{
        id: "70034",
        name: "Malden Center - Southbound",
        platform_name: "Southbound",
        location_type: 0,
        vehicle_type: :subway
      }

      malden_center_nb = %Stop{
        id: "70033",
        name: "Malden Center - Northbound",
        platform_name: "Northbound",
        location_type: 0,
        vehicle_type: :subway
      }

      malden_center_parent = %Stop{
        id: "place-mlmnl",
        name: "Malden Center",
        location_type: 1,
        child_stops: [malden_center_nb, malden_center_sb]
      }

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [
            ie(stop: oak_grove_parent, route: "Orange", route_type: 1),
            ie(stop: oak_grove_sb)
          ],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :station_closure,
          informed_entities: [
            ie(stop: malden_center_parent),
            ie(stop: malden_center_nb),
            ie(stop: malden_center_sb)
          ],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :delay,
          severity: 5,
          informed_entities: [ie(stop: oak_grove_parent)],
          active_period: happening_now_active_period
        }
      ]

      directional_alerts = [
        %Alert{
          id: "1",
          effect: :delay,
          severity: 5,
          informed_entities: [
            ie(stop: %Stop{id: "place-ogmnl", name: "Oak Grove"}, direction_id: 0)
          ],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :delay,
          severity: 5,
          informed_entities: [ie(stop: %Stop{id: "place-ogmnl", name: "Oak Grove"})],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :delay,
          severity: 5,
          informed_entities: [
            ie(stop: %Stop{id: "place-ogmnl", name: "Oak Grove"}, direction_id: 1)
          ],
          active_period: happening_now_active_period
        }
      ]

      tagged_stop_sequences = %{
        "A" => [["place-ogmnl", "place-mlmnl", "place-welln", "place-astao"]]
      }

      stop_sequences = LocationContext.untag_stop_sequences(tagged_stop_sequences)

      fetch_stop_name_fn = fn
        "place-ogmnl" -> "Oak Grove"
        "place-mlmnl" -> "Malden Center"
        "place-welln" -> "Wellington"
        "place-astao" -> "Assembly"
      end

      location_context = %LocationContext{
        home_stop: stop_id,
        tagged_stop_sequences: tagged_stop_sequences,
        upstream_stops: LocationContext.upstream_stop_id_set([stop_id], stop_sequences),
        downstream_stops: LocationContext.downstream_stop_id_set([stop_id], stop_sequences),
        routes: routes_at_stop,
        alert_route_types: LocationContext.route_type_filter(app, [stop_id])
      }

      %{
        config: config,
        bad_config: bad_config,
        location_context: location_context,
        now: ~U[2021-01-01T00:00:00Z],
        happening_now_active_period: happening_now_active_period,
        malden_center_nb: malden_center_nb,
        malden_center_sb: malden_center_sb,
        oak_grove_nb: oak_grove_nb,
        oak_grove_sb: oak_grove_sb,
        fetch_alerts_fn: fn _ -> {:ok, alerts} end,
        fetch_directional_alerts_fn: fn _ -> {:ok, directional_alerts} end,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fn _, _, _ -> {:ok, location_context} end,
        x_fetch_alerts_fn: fn _ -> :error end,
        x_fetch_stop_name_fn: fn _ -> nil end,
        x_fetch_location_context_fn: fn _, _, _ -> :error end
      }
    end

    test "returns priority instances for immediate disruptions", context do
      %{
        config: config,
        location_context: location_context,
        now: now,
        happening_now_active_period: happening_now_active_period,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fetch_location_context_fn,
        oak_grove_sb: oak_grove_sb,
        oak_grove_nb: oak_grove_nb,
        malden_center_sb: malden_center_sb,
        malden_center_nb: malden_center_nb
      } = context

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [
            ie(
              stop: %Stop{
                id: "place-ogmnl",
                name: "Oak Grove",
                location_type: 1,
                child_stops: [oak_grove_sb, oak_grove_nb]
              }
            ),
            ie(stop: oak_grove_sb)
          ],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :station_closure,
          informed_entities: [
            ie(
              stop: %Stop{
                id: "place-mlmnl",
                name: "Malden Center",
                location_type: 1,
                child_stops: [malden_center_sb, malden_center_nb]
              }
            ),
            ie(stop: malden_center_sb)
          ],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :delay,
          severity: 5,
          informed_entities: [ie(stop: %Stop{id: "place-ogmnl", name: "Oak Grove"})],
          active_period: happening_now_active_period
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        home_station_name: "Oak Grove"
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [
                ie(
                  stop: %Stop{
                    id: "place-ogmnl",
                    name: "Oak Grove",
                    location_type: 1,
                    child_stops: [oak_grove_sb, oak_grove_nb]
                  }
                ),
                ie(stop: oak_grove_sb)
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_station_names: ["Oak Grove"],
            partial_closure_platform_names: ["Southbound"]
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [
                ie(
                  stop: %Stop{
                    id: "place-mlmnl",
                    name: "Malden Center",
                    location_type: 1,
                    child_stops: [malden_center_sb, malden_center_nb]
                  }
                ),
                ie(stop: malden_center_sb)
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: false,
            informed_station_names: ["Malden Center"],
            partial_closure_platform_names: ["Southbound"]
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "3",
              effect: :delay,
              severity: 5,
              informed_entities: [ie(stop: %Stop{id: "place-ogmnl", name: "Oak Grove"})],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: false,
            informed_station_names: []
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 fetch_stop_name_fn,
                 fetch_location_context_fn
               )
    end

    test "returns priority instances for closest downstream disruptions if no immediate disruptions",
         context do
      %{
        config: config,
        location_context: location_context,
        now: now,
        happening_now_active_period: happening_now_active_period,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fetch_location_context_fn
      } = context

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [ie(stop: %Stop{id: "place-mlmnl", name: "Malden Center"})],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :station_closure,
          informed_entities: [ie(stop: %Stop{id: "place-astao", name: "Assembly"})],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :shuttle,
          informed_entities: [
            ie(stop: %Stop{id: "place-mlmnl", name: "Malden Center"}),
            ie(stop: %Stop{id: "place-welln", name: "Wellington"})
          ],
          active_period: happening_now_active_period
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        home_station_name: "Oak Grove"
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [ie(stop: %Stop{id: "place-mlmnl", name: "Malden Center"})],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_station_names: ["Malden Center"],
            partial_closure_platform_names: []
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "3",
              effect: :shuttle,
              informed_entities: [
                ie(stop: %Stop{id: "place-mlmnl", name: "Malden Center"}),
                ie(stop: %Stop{id: "place-welln", name: "Wellington"})
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_station_names: []
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [ie(stop: %Stop{id: "place-astao", name: "Assembly"})],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_station_names: ["Assembly"],
            partial_closure_platform_names: []
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 fetch_stop_name_fn,
                 fetch_location_context_fn
               )
    end

    test "returns priority instances for moderate disruptions if no immediate/downstream disruptions",
         context do
      %{
        config: config,
        location_context: location_context,
        now: now,
        happening_now_active_period: happening_now_active_period,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fetch_location_context_fn
      } = context

      alerts = [
        %Alert{
          id: "1",
          effect: :delay,
          severity: 6,
          informed_entities: [ie(stop: %Stop{id: "place-mlmnl", name: "Malden Center"})],
          active_period: happening_now_active_period
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        home_station_name: "Oak Grove"
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :delay,
              severity: 6,
              informed_entities: [ie(stop: %Stop{id: "place-mlmnl", name: "Malden Center"})],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_station_names: []
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 fetch_stop_name_fn,
                 fetch_location_context_fn
               )
    end

    test "fails when passed config for an unsupported screen type", context do
      %{
        bad_config: bad_config,
        now: now,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fetch_location_context_fn
      } = context

      assert_raise FunctionClauseError, fn ->
        reconstructed_alert_instances(
          bad_config,
          now,
          fetch_alerts_fn,
          fetch_stop_name_fn,
          fetch_location_context_fn
        )
      end
    end

    test "returns empty list if any query fails", context do
      %{
        config: config,
        now: now,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fetch_location_context_fn,
        x_fetch_alerts_fn: x_fetch_alerts_fn,
        x_fetch_location_context_fn: x_fetch_location_context_fn
      } = context

      assert [] ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 fetch_stop_name_fn,
                 x_fetch_location_context_fn
               )

      assert [] ==
               reconstructed_alert_instances(
                 config,
                 now,
                 x_fetch_alerts_fn,
                 fetch_stop_name_fn,
                 fetch_location_context_fn
               )
    end

    test "fails gracefully if get_station query fails", context do
      %{
        config: config,
        location_context: location_context,
        now: now,
        oak_grove_sb: oak_grove_sb,
        oak_grove_nb: oak_grove_nb,
        malden_center_sb: malden_center_sb,
        malden_center_nb: malden_center_nb,
        fetch_location_context_fn: fetch_location_context_fn,
        fetch_alerts_fn: fetch_alerts_fn,
        x_fetch_stop_name_fn: x_fetch_stop_name_fn
      } = context

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        home_station_name: nil,
        is_terminal_station: true
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [
                ie(
                  stop: %Stop{
                    id: "place-ogmnl",
                    name: "Oak Grove",
                    location_type: 1,
                    child_stops: [oak_grove_nb, oak_grove_sb]
                  },
                  route: "Orange",
                  route_type: 1
                ),
                ie(stop: oak_grove_sb)
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_station_names: ["Oak Grove"],
            is_priority: true,
            partial_closure_platform_names: ["Southbound"]
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [
                ie(
                  stop: %Stop{
                    id: "place-mlmnl",
                    name: "Malden Center",
                    location_type: 1,
                    child_stops: [malden_center_nb, malden_center_sb]
                  }
                ),
                ie(stop: malden_center_nb),
                ie(stop: malden_center_sb)
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_station_names: ["Malden Center"],
            partial_closure_platform_names: []
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "3",
              effect: :delay,
              severity: 5,
              informed_entities: [
                ie(
                  stop: %Stop{
                    id: "place-ogmnl",
                    name: "Oak Grove",
                    location_type: 1,
                    child_stops: [oak_grove_nb, oak_grove_sb]
                  }
                )
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: false
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 x_fetch_stop_name_fn,
                 fetch_location_context_fn
               )
    end

    test "filters delay alerts in irrelevant direction", context do
      %{
        config: config,
        location_context: location_context,
        now: now,
        fetch_directional_alerts_fn: fetch_directional_alerts_fn,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fetch_location_context_fn
      } = context

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        is_priority: true,
        home_station_name: "Oak Grove"
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :delay,
              severity: 5,
              informed_entities: [
                ie(stop: %Stop{id: "place-ogmnl", name: "Oak Grove"}, direction_id: 0)
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_station_names: []
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :delay,
              severity: 5,
              informed_entities: [ie(stop: %Stop{id: "place-ogmnl", name: "Oak Grove"})],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_station_names: []
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_directional_alerts_fn,
                 fetch_stop_name_fn,
                 fetch_location_context_fn
               )
    end

    test "filters entire route_type alerts with nil route/stop", context do
      %{
        config: config,
        location_context: location_context,
        now: now,
        happening_now_active_period: happening_now_active_period,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fetch_location_context_fn,
        malden_center_nb: malden_center_nb,
        malden_center_sb: malden_center_sb
      } = context

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [ie(route_type: 2)],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :station_closure,
          informed_entities: [
            ie(
              stop: %Stop{
                id: "place-mlmnl",
                name: "Malden Center",
                location_type: 1,
                child_stops: [malden_center_sb, malden_center_nb]
              }
            ),
            ie(stop: malden_center_sb)
          ],
          active_period: happening_now_active_period
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        is_priority: true,
        home_station_name: "Oak Grove"
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [
                ie(
                  stop: %Stop{
                    id: "place-mlmnl",
                    name: "Malden Center",
                    location_type: 1,
                    child_stops: [malden_center_sb, malden_center_nb]
                  }
                ),
                ie(stop: malden_center_sb)
              ],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: false,
            informed_station_names: ["Malden Center"],
            partial_closure_platform_names: ["Southbound"]
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 fetch_stop_name_fn,
                 fetch_location_context_fn
               )
    end
  end
end
