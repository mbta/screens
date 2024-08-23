defmodule Screens.Alerts.AlertTest do
  use ExUnit.Case, async: true

  import Mox

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route

  setup :verify_on_exit!

  defp alert_json(id) do
    %{
      "id" => id,
      "attributes" => %{
        "active_period" => [],
        "created_at" => nil,
        "updated_at" => nil,
        "cause" => nil,
        "effect" => nil,
        "header" => nil,
        "informed_entity" => [],
        "lifecycle" => nil,
        "severity" => nil,
        "timeframe" => nil,
        "url" => nil,
        "description" => nil
      }
    }
  end

  describe "fetch_by_stop_and_route/3" do
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

  defp ie(opts) do
    %{stop: opts[:stop], route: opts[:route], route_type: opts[:route_type]}
  end

  describe "informed_entities/1" do
    test "returns informed entities list from the widget's alert" do
      ies = [ie(stop: "123"), ie(stop: "1129", route: "39")]

      assert ies == Alert.informed_entities(%Alert{informed_entities: ies})
    end
  end

  describe "effect/1" do
    test "returns effect from the widget's alert" do
      effect = :detour

      assert effect == Alert.effect(%Alert{effect: effect})
    end
  end

  describe "fetch_from_cache/2" do
    setup do
      alerts = [
        %Alert{
          id: "USING_WHEELCHAIR",
          cause: :construction,
          effect: :delay,
          severity: 4,
          header: "Alert 0",
          description: "Alert 0",
          informed_entities: [
            %{
              activities: ~w[USING_WHEELCHAIR],
              stop: "A",
              route: nil,
              route_type: 3,
              direction_id: nil
            }
          ]
        },
        %Alert{
          id: "stop: A, route_type: 3",
          cause: :construction,
          effect: :delay,
          severity: 4,
          header: "Alert 1",
          description: "Alert 1",
          informed_entities: [
            %{activities: ~w[BOARD RIDE], stop: "A", route: nil, route_type: 3, direction_id: nil}
          ]
        },
        %Alert{
          id: "stop: B, route_type: 3",
          cause: :construction,
          effect: :delay,
          severity: 4,
          header: "Alert 2",
          description: "Alert 2",
          informed_entities: [
            %{activities: ~w[BOARD RIDE], stop: "B", route: nil, route_type: 3, direction_id: nil}
          ]
        },
        %Alert{
          id: "stop: C, route: Z, route_type: 2, direction_id: 0",
          cause: :construction,
          effect: :delay,
          severity: 4,
          header: "Alert 3",
          description: "Alert 3",
          informed_entities: [
            %{activities: ~w[BOARD EXIT], stop: "C", route: "Z", route_type: 2, direction_id: 0}
          ]
        },
        %Alert{
          id: "stop: D, route: Y/Z, route_type: 2, direction_id: 1",
          cause: :construction,
          effect: :delay,
          severity: 4,
          header: "Alert 4",
          description: "Alert 4",
          informed_entities: [
            %{activities: ~w[BOARD RIDE], stop: "D", route: "Z", route_type: 2, direction_id: 1},
            %{activities: ~w[BOARD RIDE], stop: nil, route: "Y", route_type: 2, direction_id: nil}
          ]
        }
      ]

      [alerts: alerts, get_all_alerts: fn -> alerts end]
    end

    test "returns all of the alerts matching the default activities", %{
      alerts: alerts,
      get_all_alerts: get_all_alerts
    } do
      assert {:ok, alerts} == Alert.fetch_from_cache([], get_all_alerts)
    end

    test "filters by stops", %{get_all_alerts: get_all_alerts} do
      stub(Route.Mock, :serving_stop, fn _ -> {:ok, []} end)

      assert {:ok, [%Alert{id: "stop: A" <> _}]} =
               Alert.fetch_from_cache([stop_id: "A"], get_all_alerts)

      assert {:ok, [%Alert{id: "stop: B" <> _}]} =
               Alert.fetch_from_cache([stop_ids: ["B"]], get_all_alerts)

      assert {:ok, [%Alert{id: "stop: A" <> _}, %Alert{id: "stop: B" <> _}]} =
               Alert.fetch_from_cache([stop_ids: ["A", "B"]], get_all_alerts)
    end

    test "filters by routes", %{get_all_alerts: get_all_alerts} do
      stub(Route.Mock, :by_id, fn
        "Z" -> {:ok, %Route{id: "Z", type: :rail}}
        "Y" -> {:ok, %Route{id: "Y", type: :rail}}
      end)

      assert {:ok, [%Alert{id: "stop: C, route: Z" <> _}, %Alert{id: "stop: D, route: Y/Z" <> _}]} =
               Alert.fetch_from_cache([route_ids: ["Z"]], get_all_alerts)

      assert {:ok, [%Alert{id: "stop: D, route: Y/Z" <> _}]} =
               Alert.fetch_from_cache([route_ids: ["Y"]], get_all_alerts)
    end

    test "filters by route_type", %{get_all_alerts: get_all_alerts} do
      assert {:ok,
              [
                %Alert{id: "stop: C, route: Z, route_type: 2" <> _},
                %Alert{id: "stop: D, route: Y/Z, route_type: 2" <> _}
              ]} =
               Alert.fetch_from_cache([route_type: :rail], get_all_alerts)

      assert {:ok,
              [
                %Alert{id: "stop: C, route: Z, route_type: 2" <> _},
                %Alert{id: "stop: D, route: Y/Z, route_type: 2" <> _}
              ]} =
               Alert.fetch_from_cache([route_type: 2], get_all_alerts)

      assert {:ok,
              [
                %Alert{id: "stop: A, route_type: 3" <> _},
                %Alert{id: "stop: B, route_type: 3" <> _}
              ]} =
               Alert.fetch_from_cache([route_types: [:bus]], get_all_alerts)
    end

    test "filters by route and direction_id", %{get_all_alerts: get_all_alerts} do
      stub(Route.Mock, :by_id, fn "Z" -> {:ok, %Route{id: "Z", type: :rail}} end)

      assert {:ok, [%Alert{id: "stop: D, route: Y/Z, route_type: 2, direction_id: 1"}]} =
               Alert.fetch_from_cache([route_ids: ["Z"], direction_id: 1], get_all_alerts)
    end

    test "filters by activities when passed", %{get_all_alerts: get_all_alerts} do
      assert {:ok, [%Alert{id: "USING_WHEELCHAIR"}]} =
               Alert.fetch_from_cache([activities: ["USING_WHEELCHAIR"]], get_all_alerts)

      assert {:ok, [%Alert{id: "stop: C, route: Z" <> _}]} =
               Alert.fetch_from_cache([activities: ["EXIT", "DOES_NOT_EXIST"]], get_all_alerts)
    end
  end
end
