defmodule Screens.V2.CandidateGenerator.Widgets.AlertsTest do
  use ExUnit.Case, async: true

  import Screens.V2.CandidateGenerator.Widgets.Alerts

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Alerts, BusShelter, Solari}
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget

  defp ie(opts \\ []) do
    %{stop: opts[:stop], route: opts[:route], route_type: opts[:route_type]}
  end

  describe "alert_instances/5" do
    setup do
      now = ~U[2021-01-01T00:00:00Z]

      config =
        struct(Screen, %{app_params: struct(BusShelter, %{alerts: %Alerts{stop_id: "1265"}})})

      bad_config = struct(Screen, %{app_params: struct(Solari)})

      routes_at_stop = [
        %{route_id: "22", active?: true},
        %{route_id: "29", active?: false},
        %{route_id: "44", active?: true}
      ]

      stop_sequences = [
        ~w[11531 1265 1266],
        ~w[1262 11531 1265 1266 10413],
        ~w[1265 1266 10413 11413 17411],
        ~w[1260 1262 11531 1265]
      ]

      alerts = [
        %Alert{
          id: "1",
          effect: :stop_closure,
          informed_entities: [ie(stop: "1265")],
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
        %Alert{id: "4", effect: :stop_closure, informed_entities: [], active_period: [{now, nil}]}
      ]

      %{
        config: config,
        bad_config: bad_config,
        routes_at_stop: routes_at_stop,
        stop_sequences: stop_sequences,
        now: now,
        fetch_simplified_routes_at_stop_fn: fn _, _ -> {:ok, routes_at_stop} end,
        fetch_stop_sequences_fn: fn _ -> {:ok, stop_sequences} end,
        fetch_alerts_fn: fn _, _ -> {:ok, alerts} end,
        x_fetch_simplified_routes_at_stop_fn: fn _, _ -> :error end,
        x_fetch_stop_sequences_fn: fn _ -> :error end,
        x_fetch_alerts_fn: fn _, _ -> :error end
      }
    end

    test "returns a list of alert widgets if all queries succeed", context do
      %{
        config: config,
        routes_at_stop: routes_at_stop,
        stop_sequences: stop_sequences,
        now: now,
        fetch_simplified_routes_at_stop_fn: fetch_simplified_routes_at_stop_fn,
        fetch_stop_sequences_fn: fetch_stop_sequences_fn,
        fetch_alerts_fn: fetch_alerts_fn
      } = context

      expected_common_data = %{
        screen: config,
        routes_at_stop: routes_at_stop,
        stop_sequences: stop_sequences,
        now: now
      }

      expected_widgets = [
        struct(
          %AlertWidget{
            alert: %Alert{
              id: "1",
              effect: :stop_closure,
              informed_entities: [ie(stop: "1265")],
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
                 fetch_simplified_routes_at_stop_fn,
                 fetch_stop_sequences_fn,
                 fetch_alerts_fn
               )
    end

    test "fails when passed config for an unsupported screen type", context do
      %{
        bad_config: bad_config,
        now: now,
        fetch_simplified_routes_at_stop_fn: fetch_simplified_routes_at_stop_fn,
        fetch_stop_sequences_fn: fetch_stop_sequences_fn,
        fetch_alerts_fn: fetch_alerts_fn
      } = context

      assert_raise FunctionClauseError, fn ->
        alert_instances(
          bad_config,
          now,
          fetch_simplified_routes_at_stop_fn,
          fetch_stop_sequences_fn,
          fetch_alerts_fn
        )
      end
    end

    test "returns empty list if any query fails", context do
      %{
        config: config,
        now: now,
        fetch_simplified_routes_at_stop_fn: fetch_simplified_routes_at_stop_fn,
        fetch_stop_sequences_fn: fetch_stop_sequences_fn,
        fetch_alerts_fn: fetch_alerts_fn,
        x_fetch_simplified_routes_at_stop_fn: x_fetch_simplified_routes_at_stop_fn,
        x_fetch_stop_sequences_fn: x_fetch_stop_sequences_fn,
        x_fetch_alerts_fn: x_fetch_alerts_fn
      } = context

      assert [] ==
               alert_instances(
                 config,
                 now,
                 x_fetch_simplified_routes_at_stop_fn,
                 fetch_stop_sequences_fn,
                 fetch_alerts_fn
               )

      assert [] ==
               alert_instances(
                 config,
                 now,
                 fetch_simplified_routes_at_stop_fn,
                 x_fetch_stop_sequences_fn,
                 fetch_alerts_fn
               )

      assert [] ==
               alert_instances(
                 config,
                 now,
                 fetch_simplified_routes_at_stop_fn,
                 fetch_stop_sequences_fn,
                 x_fetch_alerts_fn
               )
    end
  end

  describe "filter_alerts/4" do
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
               filter_alerts(alerts, stop_ids, route_ids, now)
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
               filter_alerts(alerts, stop_ids, route_ids, now)
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

      assert [%Alert{id: "1"}] = filter_alerts(alerts, stop_ids, route_ids, now)
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

      assert [] = filter_alerts(alerts, stop_ids, route_ids, now)
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

      assert [] = filter_alerts(alerts, stop_ids, route_ids, now)
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

      assert [] = filter_alerts(alerts, stop_ids, route_ids, now)
    end
  end
end
