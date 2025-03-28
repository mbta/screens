defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlertTest do
  use ExUnit.Case, async: true

  import Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.V2.WidgetInstance.ReconstructedAlert, as: ReconstructedAlertWidget
  alias ScreensConfig.Header.CurrentStopId
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.{Busway, PreFare}

  defp ie(opts) do
    %{
      stop: opts[:stop],
      route: opts[:route],
      route_type: opts[:route_type],
      direction_id: opts[:direction_id]
    }
  end

  describe "reconstructed_alert_instances/5" do
    setup do
      stop_id = "place-ogmnl"

      app = PreFare

      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(app, %{
              reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}
            })
        })

      bad_config = struct(Screen, %{app_params: struct(Busway)})

      routes_at_stop = [
        %{
          route_id: "Orange",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :subway
        }
      ]

      happening_now_active_period = [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [ie(stop: "place-ogmnl")],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :station_closure,
          informed_entities: [ie(stop: "place-mlmnl")],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :delay,
          informed_entities: [ie(stop: "place-ogmnl")],
          active_period: happening_now_active_period
        }
      ]

      directional_alerts = [
        %Alert{
          id: "1",
          effect: :delay,
          informed_entities: [ie(stop: "place-ogmnl", direction_id: 0)],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :delay,
          informed_entities: [ie(stop: "place-ogmnl")],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :delay,
          informed_entities: [ie(stop: "place-ogmnl", direction_id: 1)],
          active_period: happening_now_active_period
        }
      ]

      tagged_stop_sequences = %{
        "A" => [["place-ogmnl", "place-mlmnl", "place-welln", "place-astao"]]
      }

      stop_sequences = RoutePattern.untag_stop_sequences(tagged_stop_sequences)

      fetch_stop_name_fn = fn
        "place-ogmnl" -> "Oak Grove"
        "place-mlmnl" -> "Malden Center"
        "place-welln" -> "Wellington"
        "place-astao" -> "Assembly"
      end

      location_context = %LocationContext{
        home_stop: stop_id,
        tagged_stop_sequences: tagged_stop_sequences,
        upstream_stops: LocationContext.upstream_stop_id_set(stop_id, stop_sequences),
        downstream_stops: LocationContext.downstream_stop_id_set(stop_id, stop_sequences),
        routes: routes_at_stop,
        alert_route_types: LocationContext.route_type_filter(app, stop_id)
      }

      %{
        config: config,
        bad_config: bad_config,
        location_context: location_context,
        now: ~U[2021-01-01T00:00:00Z],
        happening_now_active_period: happening_now_active_period,
        fetch_alerts_fn: fn _ -> {:ok, alerts} end,
        fetch_directional_alerts_fn: fn _ -> {:ok, directional_alerts} end,
        fetch_stop_name_fn: fetch_stop_name_fn,
        fetch_location_context_fn: fn _, _, _ -> {:ok, location_context} end,
        fetch_subway_platforms_for_stop_fn: fn _ -> [] end,
        x_fetch_alerts_fn: fn _ -> :error end,
        x_fetch_stop_name_fn: fn _ -> :error end,
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
        fetch_subway_platforms_for_stop_fn: fetch_subway_platforms_for_stop_fn
      } = context

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [ie(stop: "place-ogmnl")],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :station_closure,
          informed_entities: [ie(stop: "place-mlmnl")],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :delay,
          informed_entities: [ie(stop: "place-ogmnl")],
          active_period: happening_now_active_period
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        all_platforms_at_informed_station: []
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-ogmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_stations: ["Oak Grove"]
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-mlmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_stations: ["Malden Center"]
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "3",
              effect: :delay,
              informed_entities: [ie(stop: "place-ogmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: false,
            informed_stations: []
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
                 fetch_location_context_fn,
                 fetch_subway_platforms_for_stop_fn
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
        fetch_location_context_fn: fetch_location_context_fn,
        fetch_subway_platforms_for_stop_fn: fetch_subway_platforms_for_stop_fn
      } = context

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [ie(stop: "place-mlmnl")],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "2",
          effect: :station_closure,
          informed_entities: [ie(stop: "place-astao")],
          active_period: happening_now_active_period
        },
        %Alert{
          id: "3",
          effect: :shuttle,
          informed_entities: [ie(stop: "place-mlmnl"), ie(stop: "place-welln")],
          active_period: happening_now_active_period
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        all_platforms_at_informed_station: []
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-mlmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_stations: ["Malden Center"]
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "3",
              effect: :shuttle,
              informed_entities: [ie(stop: "place-mlmnl"), ie(stop: "place-welln")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_stations: []
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-astao")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_stations: ["Assembly"]
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
                 fetch_location_context_fn,
                 fetch_subway_platforms_for_stop_fn
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
          informed_entities: [ie(stop: "place-mlmnl")],
          active_period: happening_now_active_period
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        is_terminal_station: true,
        all_platforms_at_informed_station: []
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :delay,
              severity: 6,
              informed_entities: [ie(stop: "place-mlmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true,
            informed_stations: []
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
        fetch_location_context_fn: fetch_location_context_fn,
        fetch_alerts_fn: fetch_alerts_fn,
        x_fetch_stop_name_fn: x_fetch_stop_name_fn,
        fetch_subway_platforms_for_stop_fn: fetch_subway_platforms_for_stop_fn
      } = context

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now,
        informed_stations: [],
        all_platforms_at_informed_station: [],
        is_terminal_station: true
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-ogmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            is_priority: true
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-mlmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            }
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "3",
              effect: :delay,
              informed_entities: [ie(stop: "place-ogmnl")],
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
                 fetch_location_context_fn,
                 fetch_subway_platforms_for_stop_fn
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
        all_platforms_at_informed_station: []
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :delay,
              informed_entities: [ie(stop: "place-ogmnl", direction_id: 0)],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_stations: []
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :delay,
              informed_entities: [ie(stop: "place-ogmnl")],
              active_period: [{~U[2020-12-31T00:00:00Z], ~U[2021-01-02T00:00:00Z]}]
            },
            informed_stations: []
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
  end
end
