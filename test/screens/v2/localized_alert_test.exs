defmodule Screens.V2.LocalizedAlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.RouteType
  alias Screens.V2.LocalizedAlert, as: LocalizedAlert
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.BusShelter

  setup :setup_base

  defp setup_base(_context) do
    %{
      widget: %AlertWidget{
        alert: %Alert{id: "123"},
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        location_context: %LocationContext{
          home_stop: nil,
          tagged_stop_sequences: nil,
          upstream_stops: nil,
          downstream_stops: nil,
          routes: nil,
          alert_route_types: nil
        }
      }
    }
  end

  defp put_home_stop(widget, app_config_module, stop_id) do
    %{
      widget
      | location_context: %{
          widget.location_context
          | alert_route_types: LocationContext.route_type_filter(app_config_module, [stop_id]),
            home_stop: stop_id
        }
    }
  end

  defp put_informed_entities(widget, ies) do
    %{widget | alert: %{widget.alert | informed_entities: ies}}
  end

  defp put_tagged_stop_sequences(widget, tagged_sequences) do
    sequences = LocationContext.untag_stop_sequences(tagged_sequences)

    %{
      widget
      | location_context: %{
          widget.location_context
          | tagged_stop_sequences: tagged_sequences,
            upstream_stops:
              LocationContext.upstream_stop_id_set([widget.location_context.home_stop], sequences),
            downstream_stops:
              LocationContext.downstream_stop_id_set(
                [widget.location_context.home_stop],
                sequences
              )
        }
    }
  end

  defp put_routes_at_stop(widget, routes) do
    %{widget | location_context: %{widget.location_context | routes: routes}}
  end

  defp put_app_id(widget, app_id) do
    %{widget | screen: %{widget.screen | app_id: app_id}}
  end

  defp put_now(widget, now) do
    %{widget | now: now}
  end

  defp ie(opts \\ []) do
    %{stop: opts[:stop], route: opts[:route], route_type: opts[:route_type]}
  end

  defp setup_home_stop(%{widget: widget}) do
    home_stop = "5"

    %{widget: put_home_stop(widget, BusShelter, home_stop)}
  end

  defp setup_tagged_stop_sequences(%{widget: widget}) do
    tagged_stop_sequences = %{
      "A" => [
        ~w[0 1 2 3 4  5 6 7 8 9],
        ~w[10 20 30 4 5 7]
      ],
      "B" => [
        ~w[           5 6 90],
        ~w[200 40     5],
        ~w[111 222 333]
      ]
    }

    %{widget: put_tagged_stop_sequences(widget, tagged_stop_sequences)}
  end

  defp setup_routes(%{widget: widget}) do
    routes = [
      %{route_id: "a", active?: true},
      %{route_id: "b", active?: false},
      %{route_id: "c", active?: true}
    ]

    %{widget: put_routes_at_stop(widget, routes)}
  end

  defp setup_location_context(%{widget: widget}) do
    %{widget: widget}
    |> setup_home_stop()
    |> setup_tagged_stop_sequences()
    |> setup_routes()
  end

  defp setup_screen_config(%{widget: widget}) do
    %{widget: put_app_id(widget, :bus_shelter_v2)}
  end

  defp setup_now(%{widget: widget}) do
    %{widget: put_now(widget, ~U[2021-01-01T00:00:00Z])}
  end

  # Pass this to `setup` to set up "context" data on the alert widget, without setting up the API alert itself.
  @alert_widget_context_setup_group [
    :setup_location_context,
    :setup_screen_config,
    :setup_now
  ]

  describe "location/1" do
    setup @alert_widget_context_setup_group

    test "handles empty informed entities", %{widget: widget} do
      widget = put_informed_entities(widget, [])

      assert :elsewhere == LocalizedAlert.location(widget)
    end

    test "handles all-nil informed entities", %{widget: widget} do
      widget = put_informed_entities(widget, [ie()])

      assert :elsewhere == LocalizedAlert.location(widget)
    end

    test "returns :elsewhere if an alert's informed entities only apply to routes not serving this stop",
         %{widget: widget} do
      widget = put_informed_entities(widget, [ie(route: "x"), ie(route: "y")])

      assert :elsewhere == LocalizedAlert.location(widget)
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

      assert :inside == LocalizedAlert.location(widget)
    end

    test "ignores route type if paired with any other specifier", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "1", route_type: RouteType.to_id(:bus)),
          ie(route: "x", route_type: RouteType.to_id(:bus)),
          ie(stop: "1", route: "x", route_type: RouteType.to_id(:bus))
        ])

      assert :upstream == LocalizedAlert.location(widget)
    end

    test "ignores route type if it doesn't match this screen's route type", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(route_type: RouteType.to_id(:light_rail))])

      assert :elsewhere == LocalizedAlert.location(widget)
    end

    test "returns :inside if any of an alert's informed entities is %{route: <route that serves this stop>}",
         %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "0"),
          ie(route: "b"),
          ie(stop: "20", route: "a")
        ])

      assert :inside == LocalizedAlert.location(widget)
    end

    test "treats active and inactive (not running on the current day) routes the same", %{
      widget: widget
    } do
      widget = put_informed_entities(widget, [ie(route: "a")])
      assert :inside == LocalizedAlert.location(widget)

      widget = put_informed_entities(widget, [ie(route: "b")])
      assert :inside == LocalizedAlert.location(widget)
    end

    test "ignores route if it doesn't serve this stop", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "1"),
          ie(route: "x")
        ])

      assert :upstream == LocalizedAlert.location(widget)
    end

    test "returns :upstream for an alert that only affects upstream stops", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "0"),
          ie(stop: "20", route: "a")
        ])

      assert :upstream == LocalizedAlert.location(widget)
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

      assert :boundary_upstream == LocalizedAlert.location(widget)
    end

    test "returns :inside for an alert that only affects this stop", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "5"),
          ie(stop: "5", route_type: RouteType.to_id(:bus)),
          ie(stop: "5", route: "a")
        ])

      assert :inside == LocalizedAlert.location(widget)
    end

    test "returns :inside for an alert that affects upstream stops, downstream stops, and this stop",
         %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "4"),
          ie(stop: "5"),
          ie(stop: "6")
        ])

      assert :inside == LocalizedAlert.location(widget)
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

      assert :boundary_downstream == LocalizedAlert.location(widget)
    end

    test "returns :downstream for an alert that only affects downstream stops", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "6"),
          ie(stop: "90", route: "a")
        ])

      assert :downstream == LocalizedAlert.location(widget)
    end

    test "returns :downstream for an alert that affects upstream and downstream stops, but not this stop",
         %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(stop: "4"),
          ie(stop: "6")
        ])

      assert :downstream == LocalizedAlert.location(widget)
    end
  end
end
