defmodule Screens.V2.WidgetInstance.ReconstructedAlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{PreFare}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.LocationContext
  alias Screens.Stops.Stop
  alias Screens.V2.AlertsWidget
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  setup :setup_base

  # Currently testing PreFare only
  defp setup_base(_context) do
    %{
      widget: %ReconstructedAlert{
        alert: %Alert{id: "123", updated_at: ~U[2023-06-09T09:00:00Z]},
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        location_context: %LocationContext{
          home_stop: nil,
          stop_sequences: nil,
          upstream_stops: nil,
          downstream_stops: nil,
          routes: nil,
          alert_route_types: nil
        }
      }
    }
  end

  defp put_active_period(widget, ap) do
    %{widget | alert: %{widget.alert | active_period: ap}}
  end

  defp put_home_stop(widget, app_config_module, stop_id) do
    %{
      widget
      | location_context: %{
          widget.location_context
          | alert_route_types: Stop.get_route_type_filter(app_config_module, stop_id),
            home_stop: stop_id
        }
    }
  end

  defp put_informed_entities(widget, ies) do
    %{widget | alert: %{widget.alert | informed_entities: ies}}
  end

  defp put_stop_sequences(widget, sequences) do
    %{
      widget
      | location_context: %{
          widget.location_context
          | stop_sequences: sequences,
            upstream_stops:
              Stop.upstream_stop_id_set(widget.location_context.home_stop, sequences),
            downstream_stops:
              Stop.downstream_stop_id_set(widget.location_context.home_stop, sequences)
        }
    }
  end

  defp put_routes_at_stop(widget, routes) do
    %{
      widget
      | location_context: %{
          widget.location_context
          | routes: routes
        }
    }
  end

  defp put_informed_stations_string(widget, string) do
    %{widget | informed_stations_string: string}
  end

  defp put_app_id(widget, app_id) do
    %{widget | screen: %{widget.screen | app_id: app_id}}
  end

  defp put_effect(widget, effect) do
    %{widget | alert: %{widget.alert | effect: effect}}
  end

  defp put_now(widget, now) do
    %{widget | now: now}
  end

  defp put_cause(widget, cause) do
    %{widget | alert: %{widget.alert | cause: cause}}
  end

  defp put_alert_header(widget, header) do
    %{widget | alert: %{widget.alert | header: header}}
  end

  defp put_severity(widget, severity) do
    %{widget | alert: %{widget.alert | severity: severity}}
  end

  defp put_is_terminal_station(widget, is_terminal_station) do
    %{widget | is_terminal_station: is_terminal_station}
  end

  defp put_is_full_screen(widget, is_full_screen) do
    %{widget | is_full_screen: is_full_screen}
  end

  defp ie(opts) do
    %{
      stop: opts[:stop],
      route: opts[:route],
      route_type: opts[:route_type],
      direction_id: opts[:direction_id]
    }
  end

  defp setup_transfer_station(%{widget: widget}) do
    home_stop = "place-dwnxg"

    stop_sequences = [
      [
        "place-ogmnl",
        "place-haecl",
        "place-dwnxg",
        "place-forhl"
      ],
      [
        "place-alfcl",
        "place-pktrm",
        "place-dwnxg",
        "place-asmnl"
      ],
      [
        "place-alfcl",
        "place-dwnxg",
        "place-sstat",
        "place-brntn"
      ]
    ]

    routes = [
      %{
        route_id: "Red",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      },
      %{
        route_id: "Orange",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      }
    ]

    widget =
      widget
      |> put_home_stop(PreFare, home_stop)
      |> put_stop_sequences(stop_sequences)
      |> put_informed_stations_string("Downtown Crossing")
      |> put_routes_at_stop(routes)

    %{widget: widget}
  end

  defp setup_single_line_station(%{widget: widget}) do
    home_stop = "place-ogmnl"

    stop_sequences = [
      [
        "place-ogmnl",
        "place-mlmnl",
        "place-welln",
        "place-astao"
      ]
    ]

    routes = [
      %{
        route_id: "Orange",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      }
    ]

    widget =
      widget
      |> put_home_stop(PreFare, home_stop)
      |> put_stop_sequences(stop_sequences)
      |> put_informed_stations_string("Oak Grove")
      |> put_routes_at_stop(routes)

    %{widget: widget}
  end

  # Setting up screen location context
  defp setup_home_stop(%{widget: widget}) do
    home_stop = "place-dwnxg"

    %{widget: put_home_stop(widget, PreFare, home_stop)}
  end

  defp setup_stop_sequences(%{widget: widget}) do
    stop_sequences = [
      [
        "place-ogmnl",
        "place-dwnxg",
        "place-chncl",
        "place-forhl"
      ],
      [
        "place-asmnl",
        "place-dwnxg",
        "place-pktrm",
        "place-alfcl"
      ],
      [
        "place-alfcl",
        "place-dwnxg",
        "place-sstat",
        "place-brntn"
      ]
    ]

    %{widget: put_stop_sequences(widget, stop_sequences)}
  end

  defp setup_informed_entities_string(%{widget: widget}) do
    %{widget: put_informed_stations_string(widget, "Downtown Crossing")}
  end

  defp setup_location_context(%{widget: widget}) do
    %{widget: widget}
    |> setup_home_stop()
    |> setup_stop_sequences()
    |> setup_routes()
  end

  defp setup_routes(%{widget: widget}) do
    routes = [
      %{
        route_id: "Red",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      },
      %{
        route_id: "Orange",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      }
    ]

    %{widget: put_routes_at_stop(widget, routes)}
  end

  defp setup_screen_config(%{widget: widget}) do
    %{widget: put_app_id(widget, :pre_fare_v2)}
  end

  defp setup_now(%{widget: widget}) do
    %{widget: put_now(widget, ~U[2021-01-01T00:00:00Z])}
  end

  # Setting up alert related stuff
  defp setup_informed_entities(%{widget: widget}) do
    %{widget: put_informed_entities(widget, [ie(stop: "place-dwnxg")])}
  end

  defp setup_active_period(%{widget: widget}) do
    active_period = [
      {~U[2021-01-01T00:00:00Z], ~U[2021-01-01T22:00:00Z]},
      {~U[2021-01-02T00:00:00Z], ~U[2021-01-02T22:00:00Z]}
    ]

    %{widget: put_active_period(widget, active_period)}
  end

  defp setup_effect(%{widget: widget}) do
    %{widget: put_effect(widget, :station_closure)}
  end

  # Pass this to `setup` to set up "context" data on the alert widget, without setting up the API alert itself.
  @transfer_stations_alert_widget_context_setup_group [
    :setup_transfer_station,
    :setup_screen_config,
    :setup_now
  ]

  @one_line_station_alert_widget_context_setup_group [
    :setup_single_line_station,
    :setup_screen_config,
    :setup_now
  ]

  @alert_widget_context_setup_group [
    :setup_location_context,
    :setup_screen_config,
    :setup_now,
    :setup_informed_entities_string
  ]

  # Pass this to `setup` to set up a stop_closure alert that is currently active (just started) and affects the home stop.
  @valid_alert_setup_group @alert_widget_context_setup_group ++
                             [
                               :setup_informed_entities,
                               :setup_active_period,
                               :setup_effect
                             ]

  describe "priority/1, slot_names/1, widget_type/1" do
    setup @valid_alert_setup_group

    test "returns takeover for a closure alert at this station", %{widget: widget} do
      widget = put_is_full_screen(widget, true)
      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
      assert :reconstructed_takeover == WidgetInstance.widget_type(widget)
    end

    test "returns takeover for a suspension that affects all station trips", %{widget: widget} do
      widget =
        put_informed_entities(widget, [
          ie(route: "Red", route_type: 1),
          ie(route: "Orange", route_type: 1)
        ])
        |> put_is_full_screen(true)

      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
      assert :reconstructed_takeover == WidgetInstance.widget_type(widget)
    end

    test "returns flex zone alert for a suspension that affects some station trips", %{
      widget: widget
    } do
      widget = put_informed_entities(widget, [ie(route: "Red", route_type: 1)])
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
      assert :reconstructed_large_alert == WidgetInstance.widget_type(widget)
    end

    test "returns flex zone alert for a downstream alert", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(stop: "place-pktrm")])
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
      assert :reconstructed_large_alert == WidgetInstance.widget_type(widget)
    end

    test "returns takeover for a terminal boundary suspension", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-forhl")
        |> put_informed_entities([ie(stop: "place-chncl"), ie(stop: "place-forhl")])
        |> put_effect(:suspension)
        |> put_stop_sequences([
          [
            "place-ogmnl",
            "place-dwnxg",
            "place-chncl",
            "place-forhl"
          ]
        ])
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)

      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
      assert :reconstructed_takeover == WidgetInstance.widget_type(widget)
    end

    test "returns takeover for a terminal boundary shuttle", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-forhl")
        |> put_informed_entities([ie(stop: "place-chncl"), ie(stop: "place-forhl")])
        |> put_effect(:shuttle)
        |> put_stop_sequences([
          [
            "place-ogmnl",
            "place-dwnxg",
            "place-chncl",
            "place-forhl"
          ]
        ])
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)

      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
      assert :reconstructed_takeover == WidgetInstance.widget_type(widget)
    end

    test "returns flex zone alert for a severe delay", %{widget: widget} do
      widget = put_effect(widget, :severe_delay)
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
      assert :reconstructed_large_alert == WidgetInstance.widget_type(widget)
    end

    test "returns flex zone alert for a boundary suspension", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(stop: "place-dwnxg"), ie(stop: "place-pktrm")])
      widget = put_effect(widget, :suspension)
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
      assert :reconstructed_large_alert == WidgetInstance.widget_type(widget)
    end

    test "returns flex zone alert for a boundary shuttle", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(stop: "place-dwnxg"), ie(stop: "place-pktrm")])
      widget = put_effect(widget, :shuttle)
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
      assert :reconstructed_large_alert == WidgetInstance.widget_type(widget)
    end

    test "returns flex zone alert for a terminal boundary delay", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-forhl")
        |> put_informed_entities([ie(stop: "place-chncl"), ie(stop: "place-forhl")])
        |> put_effect(:severe_delay)
        |> put_stop_sequences([
          [
            "place-ogmnl",
            "place-dwnxg",
            "place-chncl",
            "place-forhl"
          ]
        ])
        |> put_is_terminal_station(true)

      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
      assert :reconstructed_large_alert == WidgetInstance.widget_type(widget)
    end
  end

  describe "serialize_takeover_alert/1 single line station" do
    setup @one_line_station_alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "No Orange Line trains at Oak Grove",
        cause: "",
        routes: [%{color: :orange, text: "OL", type: :text}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "Shuttle buses replace Orange Line trains at Oak Grove",
        cause: "",
        routes: [%{color: :orange, text: "OL", type: :text}],
        effect: :shuttle,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "Station closed",
        location: "Trains skip Oak Grove",
        cause: "",
        routes: [%{color: :orange, text: "OL", type: :text}],
        effect: :station_closure,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "No Orange Line trains at Oak Grove",
        cause: "Due to construction",
        routes: [%{color: :orange, text: "OL", type: :text}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles terminal boundary suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", direction_id: 0, route_type: 1),
          ie(stop: "place-mlmnl", route: "Orange", direction_id: 0, route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "No Orange Line trains between Oak Grove and Malden Center",
        cause: "",
        routes: [%{color: :orange, text: "OL - Forest Hills", type: :text}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles terminal boundary shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", direction_id: 0, route_type: 1),
          ie(stop: "place-mlmnl", route: "Orange", direction_id: 0, route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "Shuttle buses replace Orange Line trains between Oak Grove and Malden Center",
        cause: "",
        routes: [%{color: :orange, text: "OL - Forest Hills", type: :text}],
        effect: :shuttle,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "serialize_fullscreen_alert/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "No Red Line trains at Downtown Crossing",
        cause: "",
        routes: [%{color: :red, text: "RL", type: :text}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "Shuttle buses at Downtown Crossing",
        cause: "",
        routes: [%{color: :red, text: "RL", type: :text}],
        effect: :shuttle,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "Trains skip Downtown Crossing",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RL", type: :text}],
        effect: :station_closure,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles moderate delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_severity(5)
        |> put_alert_header("Delays are happening")
        |> put_is_full_screen(true)

      expected = %{
        issue: "Trains may be delayed up to 20 minutes",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RL", type: :text}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles severe delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_severity(10)
        |> put_is_full_screen(true)
        |> put_alert_header("Delays are happening")

      expected = %{
        issue: "Trains may be delayed over 60 minutes",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RL", type: :text}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:construction)
        |> put_severity(10)
        |> put_is_full_screen(true)
        |> put_alert_header("Delays are happening")

      expected = %{
        issue: "Trains may be delayed over 60 minutes",
        location: "",
        cause: "due to construction",
        routes: [%{color: :red, text: "RL", type: :text}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "serialize_fullscreen_alert/1 transfer station" do
    setup @transfer_stations_alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles :inside station closure on 1 line", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "Trains skip Downtown Crossing",
        location: "",
        cause: "",
        routes: [%{color: :orange, text: "OL", type: :text}],
        effect: :station_closure,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles station closure affecting multiple lines", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-haecl", route: "Orange", route_type: 1),
          ie(stop: "place-haecl", route: "Green-D", route_type: 0),
          ie(stop: "place-haecl", route: "Green-E", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "Trains skip Downtown Crossing",
        location: "",
        cause: "",
        routes: [
          %{color: :green, text: "GL", type: :text},
          %{color: :orange, text: "OL", type: :text}
        ],
        effect: :station_closure,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "serialize_boundary_alert/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1, route_type: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1, route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Alewife trains",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :suspension,
        urgent: true,
        region: :boundary,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1, route_type: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1, route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Alewife trains",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :shuttle,
        urgent: true,
        region: :boundary,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles moderate delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1, route_type: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1, route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_severity(5)
        |> put_alert_header("Test Alert")

      expected = %{
        issue: "Test Alert",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :delay,
        urgent: false,
        region: :boundary,
        remedy: "",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles severe delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1, route_type: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1, route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_severity(10)

      expected = %{
        issue: "Alewife trains may be delayed over 60 minutes",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :severe_delay,
        urgent: true,
        region: :boundary,
        remedy: "",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1, route_type: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1, route_type: 1)
        ])
        |> put_cause(:construction)
        |> put_severity(10)

      expected = %{
        issue: "Alewife trains may be delayed over 60 minutes",
        location: "",
        cause: "due to construction",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :severe_delay,
        urgent: true,
        region: :boundary,
        remedy: "",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "serialize_outside_alert/1" do
    setup @one_line_station_alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles downstream suspension at one stop", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", direction_id: 1, route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Oak Grove trains",
        location: "at Malden Center",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles downstream suspension range", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1),
          ie(stop: "place-welln", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No trains",
        location: "between Malden Center and Wellington",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles downstream suspension range, one direction only", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", direction_id: 1, route: "Orange", route_type: 1),
          ie(stop: "place-welln", direction_id: 1, route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Oak Grove trains",
        location: "between Malden Center and Wellington",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles shuttle at one stop", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", direction_id: 1, route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Oak Grove trains",
        location: "at Malden Center",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :shuttle,
        urgent: false,
        region: :outside,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_informed_stations_string("Malden Center")

      expected = %{
        issue: "Trains will bypass Malden Center",
        location: "",
        cause: "",
        routes: [
          %{color: :orange, text: "ORANGE LINE", type: :text}
        ],
        effect: :station_closure,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_alert_header("Test Alert")

      expected = %{
        issue: "Test Alert",
        location: "",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :delay,
        urgent: false,
        region: :outside,
        remedy: "",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)
        |> put_informed_stations_string("Malden Center")

      expected = %{
        issue: "Trains will bypass Malden Center",
        location: "",
        cause: "due to construction",
        routes: [
          %{color: :orange, text: "ORANGE LINE", type: :text}
        ],
        effect: :station_closure,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "alert edge cases" do
    setup [:setup_screen_config, :setup_now, :setup_active_period]

    test "handles GL alert affecting all branches", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-gover")
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-north", route: "Green-B", route_type: 0),
          ie(stop: "place-north", route: "Green-C", route_type: 0),
          ie(stop: "place-north", route: "Green-D", route_type: 0),
          ie(stop: "place-north", route: "Green-E", route_type: 0),
          ie(stop: "place-spmnl", route: "Green-E", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_stop_sequences([
          [
            "place-smpmnl",
            "place-north",
            "place-haecl",
            "place-gover"
          ]
        ])
        |> put_routes_at_stop([
          %{
            route_id: "Green-D",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          },
          %{
            route_id: "Green-E",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          }
        ])

      expected = %{
        issue: "No trains",
        location: "between Science Park/West End and North Station",
        cause: "",
        routes: [%{color: :green, text: "GREEN LINE", type: :text}],
        effect: :shuttle,
        urgent: false,
        region: :outside,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 9:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "audio_serialize/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "returns same result as serialize/1", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red", route_type: 1),
          ie(stop: "place-alfcl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)

      assert WidgetInstance.serialize(widget) == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "returns [2] when alert is urgent", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      assert [2] == WidgetInstance.audio_sort_key(widget)
    end

    test "returns [2, 1] when alert is not urgent", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red", route_type: 1),
          ie(stop: "place-alfcl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)

      assert [2, 1] == WidgetInstance.audio_sort_key(widget)
    end

    test "returns [2, 2] when alert effect is :delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_alert_header("Test Alert")

      assert [2, 2] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true", %{widget: widget} do
      assert WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns ReconstructedAlertView" do
      instance = %ReconstructedAlert{}
      assert ScreensWeb.V2.Audio.ReconstructedAlertView == WidgetInstance.audio_view(instance)
    end
  end

  describe "alert_id/1" do
    test "returns alert_id", %{widget: widget} do
      assert [widget.alert.id] == AlertsWidget.alert_ids(widget)
    end
  end

  describe "Real-world alerts:" do
    test "handles OL downstream suspension" do
      stop_id = "place-welln"

      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(PreFare, %{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}})
        })

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

      alerts = [
        %Alert{
          active_period: [{~U[2022-06-24 09:13:15Z], nil}],
          cause: :unknown,
          created_at: ~U[2022-06-24 09:13:17Z],
          description:
            "Orange Line Service is running between Oak Grove and North Station and between Forest Hills and Back Bay. \r\nCustomers can use Green Line service through Downtown. \r\n\r\nAffected stops:\r\nHaymarket\r\nState\r\nDowntown Crossing\r\nChinatown\r\nTufts Medical Center",
          effect: :suspension,
          header:
            "Orange Line is suspended between North Station and Back Bay due to a structural issue with the Government Center garage. ",
          id: "450523",
          informed_entities: [
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70014"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70015"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70016"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70017"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70018"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70019"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70020"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70021"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70022"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70023"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70024"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70025"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70026"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "70027"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "place-bbsta"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "place-chncl"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "place-dwnxg"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "place-haecl"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "place-north"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "place-state"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Orange",
              route_type: 1,
              stop: "place-tumnl"
            }
          ],
          lifecycle: "NEW",
          severity: 7,
          timeframe: nil,
          updated_at: ~U[2022-06-24 09:14:52Z],
          url: nil
        }
      ]

      now = ~U[2022-06-24 12:00:00Z]
      station_sequences = [Stop.get_route_stop_sequence("Orange")]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end
      fetch_stop_name_fn = fn _ -> "Wellington" end

      fetch_location_context_fn = fn _, _, _ ->
        {:ok,
         %LocationContext{
           home_stop: stop_id,
           stop_sequences: station_sequences,
           upstream_stops: Stop.upstream_stop_id_set(stop_id, station_sequences),
           downstream_stops: Stop.downstream_stop_id_set(stop_id, station_sequences),
           routes: routes_at_stop,
           alert_route_types: Stop.get_route_type_filter(PreFare, stop_id)
         }}
      end

      alert_widgets =
        CandidateGenerator.Widgets.ReconstructedAlert.reconstructed_alert_instances(
          config,
          now,
          fetch_alerts_fn,
          fetch_stop_name_fn,
          fetch_location_context_fn
        )

      expected = %{
        issue: "No trains",
        location: "No Orange Line trains between North Station and Back Bay",
        cause: "",
        routes: [%{color: :orange, text: "OL", type: :text}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 9:14 am"
      }

      assert expected == ReconstructedAlert.serialize(List.first(alert_widgets))
    end

    test "handles GL boundary shuttle at Govt Center" do
      stop_id = "place-gover"

      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(PreFare, %{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}})
        })

      routes_at_stop = [
        %{
          route_id: "Green-B",
          active?: false,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        },
        %{
          route_id: "Green-C",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        },
        %{
          route_id: "Green-D",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        },
        %{
          route_id: "Green-E",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        },
        %{
          route_id: "Blue",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :subway
        }
      ]

      alerts = [
        %Screens.Alerts.Alert{
          active_period: [{~U[2022-06-24 09:12:00Z], nil}],
          cause: :unknown,
          created_at: ~U[2022-06-24 09:12:47Z],
          description:
            "Affected stops:\r\nLechmere\r\nScience Park/West End\r\nNorth Station\r\nHaymarket\r\nGovernment Center",
          effect: :shuttle,
          header:
            "Green Line is replaced by shuttle buses between Government Center and Union Square due to a structural issue with the Government Center Garage. Shuttle buses are not servicing Haymarket Station.",
          id: "450522",
          informed_entities: [
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-north"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70504"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "place-unsqu"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-spmnl"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70204"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70202"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70501"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70202"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70207"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-unsqu"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "place-north"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70208"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70208"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70206"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-lech"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70205"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-north"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70203"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70201"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-gover"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70206"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-unsqu"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70504"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70202"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-gover"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70201"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70504"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-lech"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70501"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70202"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70208"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-gover"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-spmnl"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70207"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70204"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70203"
            }
          ],
          lifecycle: "NEW",
          severity: 7,
          timeframe: nil,
          updated_at: ~U[2022-06-24 18:24:03Z],
          url: nil
        }
      ]

      now = ~U[2022-06-24 12:00:00Z]
      station_sequences = [Stop.get_route_stop_sequence("Green")]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end
      fetch_stop_name_fn = fn _ -> "Government Center" end

      fetch_location_context_fn = fn _, _, _ ->
        {:ok,
         %LocationContext{
           home_stop: stop_id,
           stop_sequences: station_sequences,
           upstream_stops: Stop.upstream_stop_id_set(stop_id, station_sequences),
           downstream_stops: Stop.downstream_stop_id_set(stop_id, station_sequences),
           routes: routes_at_stop,
           alert_route_types: Stop.get_route_type_filter(PreFare, stop_id)
         }}
      end

      alert_widget =
        config
        |> CandidateGenerator.Widgets.ReconstructedAlert.reconstructed_alert_instances(
          now,
          fetch_alerts_fn,
          fetch_stop_name_fn,
          fetch_location_context_fn
        )
        |> List.first()

      expected = %{
        issue: "No North Station & North trains",
        location: "",
        cause: "",
        routes: [%{color: :green, text: "GREEN LINE", type: :text}],
        effect: :shuttle,
        urgent: true,
        region: :boundary,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 6:24 pm"
      }

      assert expected == ReconstructedAlert.serialize(%{alert_widget | is_full_screen: false})
    end
  end
end
