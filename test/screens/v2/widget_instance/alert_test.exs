defmodule Screens.V2.WidgetInstance.AlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{BusShelter, Solari}
  alias Screens.RouteType
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget

  setup :setup_base

  defp setup_base(_context) do
    %{
      widget: %AlertWidget{
        alert: %Alert{id: "123"},
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil}
      }
    }
  end

  defp put_active_period(widget, ap) do
    %{widget | alert: %{widget.alert | active_period: ap}}
  end

  defp put_home_stop(widget, app_config_module, stop_id) do
    alias Screens.Config.V2.Departures
    alias Screens.Config.V2.Departures.Query.Params
    alias Screens.Config.V2.Departures.{Query, Section}

    %{
      widget
      | screen: %{
          widget.screen
          | app_params:
              struct(app_config_module, %{
                departures: %Departures{
                  sections: [%Section{query: %Query{params: %Params{stop_ids: [stop_id]}}}]
                }
              })
        }
    }
  end

  defp put_informed_entities(widget, ies) do
    %{widget | alert: %{widget.alert | informed_entities: ies}}
  end

  defp put_stop_sequences(widget, sequences) do
    %{widget | stop_sequences: sequences}
  end

  defp put_active_routes_at_stop(widget, active_routes) do
    %{widget | active_routes_at_stop: active_routes}
  end

  defp put_app_id(widget, app_id) do
    %{widget | screen: %{widget.screen | app_id: app_id}}
  end

  defp put_effect(widget, effect) do
    %{widget | alert: %{widget.alert | effect: effect}}
  end

  defp ie(opts \\ []) do
    %{
      stop: opts[:stop] || nil,
      route: opts[:route] || nil,
      route_type: opts[:route_type] || nil
    }
  end

  describe "active?/2" do
    test "simply calls Alert.happening_now?/1 on the widget's alert", %{widget: widget} do
      yes_happening_now = fn %Alert{id: "123"} -> true end
      not_happening_now = fn %Alert{id: "123"} -> false end

      assert AlertWidget.active?(widget, yes_happening_now)
      assert not AlertWidget.active?(widget, not_happening_now)
    end
  end

  describe "seconds_from_onset/2" do
    test "returns difference in seconds between now and first active period's start time", %{
      widget: widget
    } do
      start = ~U[2021-01-01 00:00:00Z]
      now = ~U[2021-01-01 01:00:00Z]

      widget = put_active_period(widget, [{start, nil}])

      expected_seconds_elapsed = 3600

      assert expected_seconds_elapsed == AlertWidget.seconds_from_onset(widget, now)
    end

    test "returns a negative value if current time is before first active period", %{
      widget: widget
    } do
      start = ~U[2021-01-01 01:00:00Z]
      now = ~U[2021-01-01 00:00:00Z]

      widget = put_active_period(widget, [{start, nil}])

      expected_seconds_elapsed = -3600

      assert expected_seconds_elapsed == AlertWidget.seconds_from_onset(widget, now)
    end

    test "returns :infinity if alert has no start", %{widget: widget} do
      now = ~U[2021-01-01 00:00:00Z]

      # no active period at all
      assert :infinity == AlertWidget.seconds_from_onset(widget, now)

      # first active period has no start date
      widget =
        put_active_period(widget, [
          {nil, ~U[2021-01-02 00:00:00Z]},
          {~U[2021-01-03 00:00:00Z], ~U[2021-01-04 00:00:00Z]}
        ])

      assert :infinity == AlertWidget.seconds_from_onset(widget, now)
    end
  end

  describe "seconds_to_next_active_period/2" do
    test "returns seconds to start of first active period after current time, if it exists", %{
      widget: widget
    } do
      now = ~U[2021-01-02 01:00:00Z]
      next_start = ~U[2021-01-03 00:00:01Z]

      widget =
        put_active_period(widget, [
          {~U[2021-01-01 00:00:00Z], ~U[2021-01-01 23:00:00Z]},
          {~U[2021-01-02 00:00:00Z], ~U[2021-01-02 23:00:00Z]},
          {next_start, ~U[2021-01-03 23:00:00Z]}
        ])

      expected_seconds_to_next_active_period = 23 * 60 * 60 + 1

      assert expected_seconds_to_next_active_period ==
               AlertWidget.seconds_to_next_active_period(widget, now)
    end

    test "returns :infinity if no active period starting after current time exists", %{
      widget: widget
    } do
      now = ~U[2021-01-02 01:00:00Z]

      # no active period at all
      assert :infinity == AlertWidget.seconds_to_next_active_period(widget, now)

      # no start date after current time
      widget =
        put_active_period(widget, [
          {nil, ~U[2021-01-01 23:00:00Z]},
          {~U[2021-01-02 00:00:00Z], ~U[2021-01-02 23:00:00Z]}
        ])

      assert :infinity == AlertWidget.seconds_to_next_active_period(widget, now)
    end
  end

  describe "home_stop_id/1" do
    test "returns stop ID from config for screen types that use only one stop ID", %{
      widget: widget
    } do
      widget = put_home_stop(widget, BusShelter, "123")

      assert "123" == AlertWidget.home_stop_id(widget)
    end

    test "fails for other screen types", %{widget: widget} do
      widget = put_home_stop(widget, Solari, "123")

      assert_raise FunctionClauseError, fn -> AlertWidget.home_stop_id(widget) end
    end

    test "fails when config is not correct shape", %{widget: widget} do
      assert_raise FunctionClauseError, fn -> AlertWidget.home_stop_id(widget) end
    end
  end

  describe "informed_entities/1" do
    test "returns informed entities list from the widget's alert", %{widget: widget} do
      ies = [ie(stop: "123"), ie(stop: "1129", route: "39")]

      widget = put_informed_entities(widget, ies)

      assert ies == AlertWidget.informed_entities(widget)
    end
  end

  defp setup_home_stop(%{widget: widget}) do
    home_stop = "5"

    %{widget: put_home_stop(widget, BusShelter, home_stop)}
  end

  defp setup_stop_sequences(%{widget: widget}) do
    stop_sequences = [
      ~w[0 1 2 3 4  5 6 7 8 9],
      ~w[10 20 30 4 5 7],
      ~w[           5 6 90],
      ~w[200 40     5],
      ~w[111 222 333]
    ]

    %{widget: put_stop_sequences(widget, stop_sequences)}
  end

  defp setup_active_routes(%{widget: widget}) do
    active_routes = ~w[a b c]

    %{widget: put_active_routes_at_stop(widget, active_routes)}
  end

  defp setup_screen_config(%{widget: widget}) do
    %{widget: put_app_id(widget, :bus_shelter_v2)}
  end

  describe "upstream_stop_id_set/1" do
    setup [:setup_home_stop, :setup_stop_sequences]

    test "collects all stops upstream of the home stop into a set", %{widget: widget} do
      expected_upstream_stops = MapSet.new(~w[0 1 2 3 4] ++ ~w[10 20 30 4] ++ ~w[200 40])

      assert MapSet.equal?(expected_upstream_stops, AlertWidget.upstream_stop_id_set(widget))
    end
  end

  describe "downstream_stop_id_set/1" do
    setup [:setup_home_stop, :setup_stop_sequences]

    test "collects all stops downstream of the home stop into a set", %{widget: widget} do
      expected_downstream_stops = MapSet.new(~w[6 7 8 9] ++ ~w[7] ++ ~w[6 90])

      assert MapSet.equal?(expected_downstream_stops, AlertWidget.downstream_stop_id_set(widget))
    end
  end

  describe "location/1" do
    setup [:setup_home_stop, :setup_stop_sequences, :setup_active_routes, :setup_screen_config]

    test "handles empty informed entities", %{widget: widget} do
      widget = put_informed_entities(widget, [])

      assert :elsewhere == AlertWidget.location(widget)
    end

    test "handles all-nil informed entities", %{widget: widget} do
      widget = put_informed_entities(widget, [ie()])

      assert :elsewhere == AlertWidget.location(widget)
    end

    test "returns :elsewhere if an alert's informed entities only apply to routes not serving this stop",
         %{widget: widget} do
      widget = put_informed_entities(widget, [ie(route: "x"), ie(route: "y")])

      assert :elsewhere == AlertWidget.location(widget)
    end

    test "returns :inside if any of an alert's informed entities is %{route_type: <route type of this screen>}",
         %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "0"),
          ie(route_type: RouteType.to_id(:bus)),
          ie(route: "x"),
          ie(stop: "20", route: "a"),
          ie()
        ])

      assert :inside == AlertWidget.location(widget)
    end

    test "ignores route type if paired with any other specifier", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "1", route_type: RouteType.to_id(:bus)),
          ie(route: "x", route_type: RouteType.to_id(:bus)),
          ie(stop: "1", route: "x", route_type: RouteType.to_id(:bus))
        ])

      assert :upstream == AlertWidget.location(widget)
    end

    test "ignores route type if it doesn't match this screen's route type", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(route_type: RouteType.to_id(:light_rail))])

      assert :elsewhere == AlertWidget.location(widget)
    end

    test "returns :inside if any of an alert's informed entities is %{route: <route that is actively serving this stop>}",
         %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "0"),
          ie(route: "b"),
          ie(stop: "20", route: "a")
        ])

      assert :inside == AlertWidget.location(widget)
    end

    test "ignores route if it isn't actively serving this stop", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "1"),
          ie(route: "x")
        ])

      assert :upstream == AlertWidget.location(widget)
    end

    test "returns :upstream for an alert that only affects upstream stops", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "0"),
          ie(stop: "20", route: "a")
        ])

      assert :upstream == AlertWidget.location(widget)
    end

    test "returns :boundary_upstream for an alert that affects upstream stops and this stop", %{
      widget: widget
    } do
      widget =
        put_informed_entities(widget, [
          ie(stop: "0"),
          ie(stop: "5"),
          ie(stop: "20", route: "a")
        ])

      assert :boundary_upstream == AlertWidget.location(widget)
    end

    test "returns :inside for an alert that only affects this stop", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "5"),
          ie(stop: "5", route_type: RouteType.to_id(:bus)),
          ie(stop: "5", route: "a")
        ])

      assert :inside == AlertWidget.location(widget)
    end

    test "returns :inside for an alert that affects upstream stops, downstream stops, and this stop",
         %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "4"),
          ie(stop: "5"),
          ie(stop: "6")
        ])

      assert :inside == AlertWidget.location(widget)
    end

    test "returns :boundary_downstream for an alert that affects downstream stops and this stop",
         %{
           widget: widget
         } do
      widget =
        put_informed_entities(widget, [
          ie(stop: "6"),
          ie(stop: "5"),
          ie(stop: "90", route: "a")
        ])

      assert :boundary_downstream == AlertWidget.location(widget)
    end

    test "returns :downstream for an alert that only affects downstream stops", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "6"),
          ie(stop: "90", route: "a")
        ])

      assert :downstream == AlertWidget.location(widget)
    end

    test "returns :elsewhere for an alert that affects upstream and downstream stops, but not this stop",
         %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "4"),
          ie(stop: "6")
        ])

      assert :elsewhere == AlertWidget.location(widget)
    end
  end

  describe "effect/1" do
    test "returns effect from the widget's alert", %{widget: widget} do
      effect = :detour

      widget = put_effect(widget, effect)

      assert effect == AlertWidget.effect(widget)
    end
  end
end
