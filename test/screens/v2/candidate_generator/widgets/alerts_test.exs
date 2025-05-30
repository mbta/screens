defmodule Screens.V2.CandidateGenerator.Widgets.AlertsTest do
  use ExUnit.Case, async: true

  import Screens.V2.CandidateGenerator.Widgets.Alerts

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias ScreensConfig.{Alerts, MultiStopAlerts, Screen}
  alias ScreensConfig.Screen.{BusEink, BusShelter}

  defp ie(opts \\ []) do
    %{stop: opts[:stop], route: opts[:route], route_type: opts[:route_type]}
  end

  # credo:disable-for-next-line
  # TODO: GL e-ink needs to be specifically tested here, because sometimes the alerts are rendered slightly differently

  describe "alert_instances/4" do
    setup do
      now = ~U[2021-01-01T00:00:00Z]
      stop_id = "1265"
      multi_stop_ids = [stop_id, "1260"]
      app = BusShelter
      multi_stop_app = BusEink
      config = struct(Screen, %{app_params: struct(app, %{alerts: %Alerts{stop_id: stop_id}})})

      multi_stop_config =
        struct(Screen, %{
          app_params:
            struct(multi_stop_app, %{alerts: %MultiStopAlerts{stop_ids: multi_stop_ids}})
        })

      routes_at_stop = [
        %{route_id: "22", active?: true},
        %{route_id: "29", active?: false},
        %{route_id: "44", active?: true}
      ]

      tagged_stop_sequences = %{
        "A" => [~w[11531 1265 1266]],
        "B" => [~w[1262 11531 1265 1266 10413]],
        "C" => [~w[1265 1266 10413 11413 17411]],
        "D" => [~w[1260 1262 11531 1265]]
      }

      stop_sequences = LocationContext.untag_stop_sequences(tagged_stop_sequences)

      alerts = [
        %Alert{
          id: "1",
          effect: :stop_closure,
          informed_entities: [ie(stop: "1265"), ie(stop: "11531")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "2",
          effect: :stop_closure,
          informed_entities: [ie(route: "22")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "3",
          effect: :delay,
          informed_entities: [ie(stop: "1265")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "4",
          effect: :stop_closure,
          informed_entities: [],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "5",
          effect: :stop_closure,
          informed_entities: [ie(stop: "1262")],
          active_period: [{now, nil}]
        }
      ]

      location_context = %LocationContext{
        home_stop: stop_id,
        tagged_stop_sequences: tagged_stop_sequences,
        upstream_stops: LocationContext.upstream_stop_id_set([stop_id], stop_sequences),
        downstream_stops: LocationContext.downstream_stop_id_set([stop_id], stop_sequences),
        routes: routes_at_stop,
        alert_route_types: LocationContext.route_type_filter(app, [stop_id])
      }

      multi_stop_context = %LocationContext{
        home_stop: nil,
        tagged_stop_sequences: tagged_stop_sequences,
        upstream_stops: LocationContext.upstream_stop_id_set(multi_stop_ids, stop_sequences),
        downstream_stops: LocationContext.downstream_stop_id_set(multi_stop_ids, stop_sequences),
        routes: routes_at_stop,
        alert_route_types: LocationContext.route_type_filter(multi_stop_app, multi_stop_ids)
      }

      %{
        config: config,
        multi_stop_config: multi_stop_config,
        location_context: location_context,
        multi_stop_context: multi_stop_context,
        now: now,
        fetch_alerts_fn: fn _, _ -> {:ok, alerts} end,
        fetch_location_context_fn: fn _, _, _ -> {:ok, location_context} end,
        fetch_multi_stop_context_fn: fn _, _, _ -> {:ok, multi_stop_context} end,
        x_fetch_alerts_fn: fn _, _ -> :error end,
        x_fetch_location_context_fn: fn _, _, _ -> :error end
      }
    end

    test "returns a list of alert widgets if all queries succeed", context do
      %{
        config: config,
        location_context: location_context,
        now: now,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_location_context_fn: fetch_location_context_fn
      } = context

      expected_common_data = %{
        screen: config,
        location_context: location_context,
        now: now
      }

      expected_widgets = [
        struct(
          %AlertWidget{
            alert: %Alert{
              id: "1",
              effect: :stop_closure,
              informed_entities: [ie(stop: "1265"), ie(stop: "11531")],
              active_period: [{now, nil}]
            }
          },
          expected_common_data
        ),
        struct(
          %AlertWidget{
            alert: %Alert{
              id: "2",
              effect: :stop_closure,
              informed_entities: [ie(route: "22")],
              active_period: [{now, nil}]
            }
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 fetch_location_context_fn
               )
    end

    test "returns empty list if any query fails", context do
      %{
        config: config,
        now: now,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_location_context_fn: fetch_location_context_fn,
        x_fetch_alerts_fn: x_fetch_alerts_fn,
        x_fetch_location_context_fn: x_fetch_location_context_fn
      } = context

      assert [] ==
               alert_instances(
                 config,
                 now,
                 fetch_alerts_fn,
                 x_fetch_location_context_fn
               )

      assert [] ==
               alert_instances(
                 config,
                 now,
                 x_fetch_alerts_fn,
                 fetch_location_context_fn
               )
    end

    test "returns alert widgets for multiple stops", context do
      %{
        multi_stop_config: config,
        multi_stop_context: location_context,
        now: now,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_multi_stop_context_fn: fetch_location_context_fn
      } = context

      expected_common_data = %{screen: config, location_context: location_context, now: now}

      expected_widgets = [
        struct(
          %AlertWidget{
            alert: %Alert{
              id: "1",
              effect: :stop_closure,
              informed_entities: [ie(stop: "1265"), ie(stop: "11531")],
              active_period: [{now, nil}]
            }
          },
          expected_common_data
        ),
        struct(
          %AlertWidget{
            alert: %Alert{
              id: "2",
              effect: :stop_closure,
              informed_entities: [ie(route: "22")],
              active_period: [{now, nil}]
            }
          },
          expected_common_data
        ),
        struct(
          %AlertWidget{
            alert: %Alert{
              id: "5",
              effect: :stop_closure,
              informed_entities: [ie(stop: "1262")],
              active_period: [{now, nil}]
            }
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               alert_instances(config, now, fetch_alerts_fn, fetch_location_context_fn)
    end
  end

  describe "relevant_alerts/4" do
    setup do
      %{
        stop_ids: ~w[1 2 3],
        route_ids: ~w[11 22 33],
        now: DateTime.utc_now()
      }
    end

    test "filters out alerts that inform routes that do not serve the home stop", %{
      stop_ids: stop_ids,
      route_ids: route_ids,
      now: now
    } do
      alerts = [
        %Alert{
          id: "1",
          effect: :suspension,
          informed_entities: [ie(stop: "1")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "2",
          effect: :suspension,
          informed_entities: [ie(route: "11")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "3",
          effect: :suspension,
          informed_entities: [ie(stop: "1", route: "11")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "4",
          effect: :suspension,
          informed_entities: [ie(route: "88")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "5",
          effect: :suspension,
          informed_entities: [ie(stop: "1", route: "99")],
          active_period: [{now, nil}]
        }
      ]

      assert [%Alert{id: "1"}, %Alert{id: "2"}, %Alert{id: "3"}] =
               relevant_alerts(alerts, stop_ids, route_ids, now)
    end

    test "filters out alerts that inform stops that are not downstream of the home stop", %{
      stop_ids: stop_ids,
      route_ids: route_ids,
      now: now
    } do
      alerts = [
        %Alert{
          id: "1",
          effect: :suspension,
          informed_entities: [ie(stop: "1")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "2",
          effect: :suspension,
          informed_entities: [ie(route: "11")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "3",
          effect: :suspension,
          informed_entities: [ie(stop: "1", route: "22")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "4",
          effect: :suspension,
          informed_entities: [ie(stop: "8")],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "5",
          effect: :suspension,
          informed_entities: [ie(stop: "9", route: "33")],
          active_period: [{now, nil}]
        }
      ]

      assert [%Alert{id: "1"}, %Alert{id: "2"}, %Alert{id: "3"}] =
               relevant_alerts(alerts, stop_ids, route_ids, now)
    end

    test "keeps alerts that inform an entire route type", %{
      stop_ids: stop_ids,
      route_ids: route_ids,
      now: now
    } do
      alerts = [
        %Alert{
          id: "1",
          effect: :suspension,
          informed_entities: [ie(route_type: 1)],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "2",
          effect: :suspension,
          informed_entities: [ie(stop: "9", route_type: 1)],
          active_period: [{now, nil}]
        },
        %Alert{
          id: "3",
          effect: :suspension,
          informed_entities: [ie(route: "99", route_type: 1)],
          active_period: [{now, nil}]
        }
      ]

      assert [%Alert{id: "1"}] = relevant_alerts(alerts, stop_ids, route_ids, now)
    end

    test "filters out alerts with other informed entities", %{
      stop_ids: stop_ids,
      route_ids: route_ids,
      now: now
    } do
      alerts = [
        %Alert{
          id: "1",
          effect: :suspension,
          informed_entities: [ie()],
          active_period: [{now, nil}]
        }
      ]

      assert [] = relevant_alerts(alerts, stop_ids, route_ids, now)
    end

    test "filters out alerts that do not have a relevant effect", %{
      stop_ids: stop_ids,
      route_ids: route_ids,
      now: now
    } do
      alerts = [
        %Alert{
          id: "1",
          effect: :extra_service,
          informed_entities: [ie(stop: "1")],
          active_period: [{now, nil}]
        }
      ]

      assert [] = relevant_alerts(alerts, stop_ids, route_ids, now)
    end

    test "filters out upcoming alerts", %{
      stop_ids: stop_ids,
      route_ids: route_ids,
      now: now
    } do
      alerts = [
        %Alert{
          id: "1",
          effect: :extra_service,
          informed_entities: [ie(stop: "1")],
          active_period: [{~U[3021-01-01T00:00:00Z], nil}]
        }
      ]

      assert [] = relevant_alerts(alerts, stop_ids, route_ids, now)
    end
  end
end
