defmodule Screens.V2.WidgetInstance.ReconstructedAlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{PreFare}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  setup :setup_base

  # Currently testing PreFare only
  defp setup_base(_context) do
    %{
      widget: %ReconstructedAlert{
        alert: %Alert{id: "123"},
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil}
      }
    }
  end

  defp put_active_period(widget, ap) do
    %{widget | alert: %{widget.alert | active_period: ap}}
  end

  defp put_home_stop(widget, app_config_module, stop_id) do
    %{
      widget
      | screen: %{
          widget.screen
          | app_params:
              struct(app_config_module, %{
                reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}
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

  defp put_routes_at_stop(widget, routes) do
    %{widget | routes_at_stop: routes}
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

  defp ie(opts) do
    %{
      stop: opts[:stop],
      route: opts[:route],
      route_type: opts[:route_type],
      direction_id: opts[:direction_id]
    }
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
    %{widget: put_informed_stations_string(widget, "Alewife")}
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
  @alert_widget_context_setup_group [
    :setup_home_stop,
    :setup_stop_sequences,
    :setup_routes,
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
      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
      assert :reconstructed_takeover == WidgetInstance.widget_type(widget)
    end

    test "returns takeover for a suspension that affects all station trips", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(route: "Red"), ie(route: "Orange")])
      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
      assert :reconstructed_takeover == WidgetInstance.widget_type(widget)
    end

    test "returns flex zone alert for a suspension that affects some station trips", %{
      widget: widget
    } do
      widget = put_informed_entities(widget, [ie(route: "Red")])
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
  end

  describe "serialize_takeover_alert/2" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red"),
          ie(stop: "place-dwnxg", route: "Orange")
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: %{icon: nil, text: ["No", %{route: "red"}, %{route: "orange"}, "trains"]},
        location: "at Downtown Crossing",
        cause: "",
        routes: [
          %{color: :orange, text: "OL", type: :text},
          %{color: :red, text: "RL", type: :text}
        ],
        effect: :suspension,
        urgent: true,
        region: :inside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red"),
          ie(stop: "place-dwnxg", route: "Orange")
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: %{icon: nil, text: ["No", %{route: "red"}, %{route: "orange"}, "trains"]},
        location: "at Downtown Crossing",
        cause: "",
        routes: [
          %{color: :orange, text: "OL", type: :text},
          %{color: :red, text: "RL", type: :text}
        ],
        effect: :shuttle,
        urgent: true,
        region: :inside,
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red"),
          ie(stop: "place-dwnxg", route: "Orange")
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "Station Closed",
        location: "",
        cause: "",
        routes: [
          %{color: :orange, text: "OL", type: :text},
          %{color: :red, text: "RL", type: :text}
        ],
        effect: :station_closure,
        urgent: true,
        region: :inside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red"),
          ie(stop: "place-dwnxg", route: "Orange")
        ])
        |> put_cause(:construction)

      expected = %{
        issue: %{icon: nil, text: ["No", %{route: "red"}, %{route: "orange"}, "trains"]},
        location: "at Downtown Crossing",
        cause: "Due to construction",
        routes: [
          %{color: :orange, text: "OL", type: :text},
          %{color: :red, text: "RL", type: :text}
        ],
        effect: :suspension,
        urgent: true,
        region: :inside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles terminal boundary suspension", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-forhl")
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-grnst", route: "Orange", direction_id: 1),
          ie(stop: "place-forhl", route: "Orange", direction_id: 1)
        ])
        |> put_cause(:unknown)
        |> put_stop_sequences([
          [
            "place-jaksn",
            "place-sbmnl",
            "place-grnst",
            "place-forhl"
          ]
        ])
        |> put_is_terminal_station(true)
        |> put_routes_at_stop([
          %{
            route_id: "Orange",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          }
        ])

      expected = %{
        issue: %{icon: nil, text: ["No", %{route: "orange"}, "trains"]},
        location: "between Green Street and Forest Hills",
        cause: "",
        routes: [
          %{color: :orange, text: "ORANGE LINE", type: :text}
        ],
        effect: :suspension,
        urgent: true,
        region: :inside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles terminal boundary shuttle", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-forhl")
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-grnst", route: "Orange", direction_id: 1),
          ie(stop: "place-forhl", route: "Orange", direction_id: 1)
        ])
        |> put_cause(:unknown)
        |> put_stop_sequences([
          [
            "place-jaksn",
            "place-sbmnl",
            "place-grnst",
            "place-forhl"
          ]
        ])
        |> put_is_terminal_station(true)
        |> put_routes_at_stop([
          %{
            route_id: "Orange",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          }
        ])

      expected = %{
        issue: %{icon: nil, text: ["No", %{route: "orange"}, "trains"]},
        location: "between Green Street and Forest Hills",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :shuttle,
        urgent: true,
        region: :inside,
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "serialize_inside_flex_alert/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red")
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No trains",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :suspension,
        urgent: true,
        region: :inside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red")
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No trains",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :shuttle,
        urgent: true,
        region: :inside,
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red")
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "Red line platform closed",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :station_closure,
        urgent: true,
        region: :inside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles moderate delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red")
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
        region: :inside,
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles severe delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red")
        ])
        |> put_cause(:unknown)
        |> put_severity(10)

      expected = %{
        issue: "Trains may be delayed over 60 minutes",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :severe_delay,
        urgent: true,
        region: :inside,
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red")
        ])
        |> put_cause(:construction)
        |> put_severity(10)

      expected = %{
        issue: "Trains may be delayed over 60 minutes",
        location: "",
        cause: "due to construction",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :severe_delay,
        urgent: true,
        region: :inside,
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "serialize_boundary_alert/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles moderate delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1)
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
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles severe delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1)
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
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", direction_id: 1),
          ie(stop: "place-pktrm", route: "Red", direction_id: 1)
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
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end
  end

  describe "serialize_outside_alert/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles suspension at one stop", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([ie(stop: "place-alfcl", direction_id: 1, route: "Red")])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Alewife trains",
        location: "at Alewife",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles shuttle at one stop", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([ie(stop: "place-alfcl", direction_id: 1, route: "Red")])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Alewife trains",
        location: "at Alewife",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :shuttle,
        urgent: false,
        region: :outside,
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red"),
          ie(stop: "place-alfcl", route: "Orange")
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "Trains will bypass Alewife",
        location: "",
        cause: "",
        routes: [
          %{color: :orange, text: "OL", type: :text},
          %{color: :red, text: "RL", type: :text}
        ],
        effect: :station_closure,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red")
        ])
        |> put_cause(:unknown)
        |> put_alert_header("Test Alert")

      expected = %{
        issue: "Test Alert",
        location: "",
        cause: "",
        routes: [%{color: :red, text: "RED LINE", type: :text}],
        effect: :delay,
        urgent: false,
        region: :outside,
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red"),
          ie(stop: "place-alfcl", route: "Orange")
        ])
        |> put_cause(:construction)

      expected = %{
        issue: "Trains will bypass Alewife",
        location: "",
        cause: "due to construction",
        routes: [
          %{color: :orange, text: "OL", type: :text},
          %{color: :red, text: "RL", type: :text}
        ],
        effect: :station_closure,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
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
          ie(stop: "place-alfcl", route: "Red"),
          ie(stop: "place-alfcl", route: "Orange")
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
          ie(stop: "place-dwnxg", route: "Red")
        ])
        |> put_cause(:unknown)

      assert [2] == WidgetInstance.audio_sort_key(widget)
    end

    test "returns [2, 1] when alert is not urgent", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red"),
          ie(stop: "place-alfcl", route: "Orange")
        ])
        |> put_cause(:construction)

      assert [2, 1] == WidgetInstance.audio_sort_key(widget)
    end

    test "returns [2, 2] when alert effect is :delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red")
        ])
        |> put_cause(:unknown)
        |> put_alert_header("Test Alert")

      assert [2, 2] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true" do
      instance = %ReconstructedAlert{}
      assert WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns ReconstructedAlertView" do
      instance = %ReconstructedAlert{}
      assert ScreensWeb.V2.Audio.ReconstructedAlertView == WidgetInstance.audio_view(instance)
    end
  end
end
