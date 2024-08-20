defmodule Screens.Alerts.Cache.FilterTest do
  use ExUnit.Case, async: true

  import Mox

  alias Screens.Alerts.Alert
  alias Screens.Alerts.Cache.Filter
  alias Screens.Routes.Route

  setup :verify_on_exit!

  describe "filter_by/2" do
    setup do
      alerts = [
        alert("stop only", ie(stop: "stop-only")),
        alert("route serving stop", ie(route: "serving-stop")),
        alert("route only", ie(route: "route-only", route_type: 0)),
        alert("stop and route", ie(stop: "stop-and-route-stop", route: "stop-and-route-route")),
        alert("route only 2", ie(route: "route-only-2", route_type: 1)),
        alert("route type only", ie(route_type: 0)),
        alert(
          "route in one direction",
          ie(route: "route-in-direction", direction_id: 0, route_type: 3)
        ),
        alert(
          "route in the other direction",
          ie(route: "route-in-direction", direction_id: 1, route_type: 3)
        ),
        alert("route in either direction", ie(route: "route-in-direction", route_type: 3)),
        alert("other activities 1", ie(route: "route-only", activities: ~w[USING_WHEELCHAIR])),
        alert("other activities 2", ie(route: "route-only-3", activities: ~w[USING_WHEELCHAIR]))
      ]

      %{alerts: alerts}
    end

    test "filters for stop, including alerts impacting routes serving the stop", %{alerts: alerts} do
      stub(Route.Mock, :serving_stop, fn _ -> {:ok, [%Route{id: "serving-stop"}]} end)

      assert [%Alert{id: "stop only"}, %Alert{id: "route serving stop"}] =
               Filter.filter_by(alerts, %{stops: ["stop-only"]})
    end

    test "filters for route, including alerts impacting the entire route type", %{alerts: alerts} do
      stub(Route.Mock, :by_id, fn
        "route-only" -> {:ok, %Route{id: "route-only", type: :light_rail}}
      end)

      assert [%Alert{id: "route only"}, %Alert{id: "route type only"}] =
               Filter.filter_by(alerts, %{routes: ["route-only"]})
    end

    test "filters for stop and route combined", %{alerts: alerts} do
      stub(Route.Mock, :by_id, fn
        "stop-and-route-route" -> {:ok, %Route{id: "stop-and-route-route", type: :subway}}
        "route-only-2" -> {:ok, %Route{id: "route-only", type: :subway}}
      end)

      stub(Route.Mock, :serving_stop, fn "stop-and-route-stop" ->
        {:ok, [%Route{id: "stop-and-route-route"}]}
      end)

      assert [%Alert{id: "stop and route"}, %Alert{id: "route only 2"}] =
               Filter.filter_by(alerts, %{
                 routes: ["stop-and-route-route", "route-only-2"],
                 stops: ["stop-and-route-stop"]
               })
    end

    test "filters for route_type", %{alerts: alerts} do
      assert [%Alert{id: "route only"}, %Alert{id: "route type only"}] =
               Filter.filter_by(alerts, %{route_types: [0]})

      assert [%Alert{id: "route only 2"}] = Filter.filter_by(alerts, %{route_types: [1]})

      assert [%Alert{id: "route only"}, %Alert{id: "route only 2"}, %Alert{id: "route type only"}] =
               Filter.filter_by(alerts, %{route_types: [0, 1]})
    end

    test "filters for a specific direction_id", %{alerts: alerts} do
      stub(Route.Mock, :by_id, fn
        "route-in-direction" -> {:ok, %Route{id: "route-in-direction", type: :bus}}
      end)

      assert [%Alert{id: "route in one direction"}, %Alert{id: "route in either direction"}] =
               Filter.filter_by(alerts, %{routes: ["route-in-direction"], direction_id: 0})

      assert [%Alert{id: "route in the other direction"}, %Alert{id: "route in either direction"}] =
               Filter.filter_by(alerts, %{routes: ["route-in-direction"], direction_id: 1})
    end

    test "filters on activities", %{alerts: alerts} do
      stub(Route.Mock, :by_id, fn
        "route-only" -> {:ok, %Route{id: "route-only", type: :light_rail}}
        "route-only-3" -> {:ok, %Route{id: "route-only-3", type: :light_rail}}
      end)

      assert [%Alert{id: "other activities 1"}, %Alert{id: "other activities 2"}] =
               Filter.filter_by(alerts, %{activities: ~w[USING_WHEELCHAIR]})

      assert [%Alert{id: "other activities 1"}] =
               Filter.filter_by(alerts, %{
                 routes: ["route-only"],
                 activities: ~w[USING_WHEELCHAIR]
               })

      assert [%Alert{id: "other activities 2"}] =
               Filter.filter_by(alerts, %{
                 routes: ["route-only-3"],
                 activities: ~w[USING_WHEELCHAIR]
               })
    end
  end

  defp alert(id, ies) do
    %Alert{id: id, informed_entities: List.wrap(ies)}
  end

  defp ie(opts) do
    %{
      stop: opts[:stop],
      route: opts[:route],
      route_type: opts[:route_type],
      activities: opts[:activities] || ~w[BOARD EXIT RIDE],
      direction_id: opts[:direction_id]
    }
  end
end
