defmodule Screens.V2.WidgetInstance.ReconstructedAlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{CRDepartures, PreFare}
  alias ScreensConfig.V2.Header.CurrentStopId
  alias Screens.LocationContext
  alias Screens.RoutePatterns.RoutePattern
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
          tagged_stop_sequences: nil,
          upstream_stops: nil,
          downstream_stops: nil,
          routes: nil,
          alert_route_types: nil
        },
        all_platforms_at_informed_station: []
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

  defp put_tagged_stop_sequences(widget, tagged_sequences) do
    sequences = RoutePattern.untag_stop_sequences(tagged_sequences)

    %{
      widget
      | location_context: %{
          widget.location_context
          | tagged_stop_sequences: tagged_sequences,
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

  defp put_informed_stations(widget, stations) do
    %{widget | informed_stations: stations}
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

  defp put_pair_with_cr_widget(widget, pair_with_alert_widget) do
    cr_departures =
      struct(CRDepartures,
        enabled: pair_with_alert_widget,
        pair_with_alert_widget: pair_with_alert_widget
      )

    app_params = struct(PreFare, cr_departures: cr_departures)

    %{
      widget
      | screen: %Screen{widget.screen | app_params: app_params}
    }
  end

  defp put_all_platforms_at_informed_station(widget, all_platforms_at_informed_station) do
    %{widget | all_platforms_at_informed_station: all_platforms_at_informed_station}
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

    tagged_stop_sequences = %{
      "Orange" => [
        [
          "place-ogmnl",
          "place-haecl",
          "place-state",
          "place-dwnxg",
          "place-chncl",
          "place-forhl"
        ]
      ],
      "Red" => [
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
    }

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
      |> put_tagged_stop_sequences(tagged_stop_sequences)
      |> put_informed_stations(["Downtown Crossing"])
      |> put_routes_at_stop(routes)

    %{widget: widget}
  end

  defp setup_single_line_station(%{widget: widget}) do
    home_stop = "place-mlmnl"

    tagged_stop_sequences = %{
      "Orange" => [
        [
          "place-ogmnl",
          "place-mlmnl",
          "place-welln",
          "place-astao"
        ]
      ]
    }

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
      |> put_tagged_stop_sequences(tagged_stop_sequences)
      |> put_informed_stations(["Malden Center"])
      |> put_routes_at_stop(routes)

    %{widget: widget}
  end

  # Setting up screen location context
  defp setup_home_stop(%{widget: widget}) do
    home_stop = "place-dwnxg"

    %{widget: put_home_stop(widget, PreFare, home_stop)}
  end

  defp setup_tagged_stop_sequences(%{widget: widget}) do
    tagged_stop_sequences = %{
      "Orange" => [
        [
          "place-ogmnl",
          "place-dwnxg",
          "place-chncl",
          "place-forhl"
        ]
      ],
      "Red" => [
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
    }

    %{widget: put_tagged_stop_sequences(widget, tagged_stop_sequences)}
  end

  defp setup_informed_entities_string(%{widget: widget}) do
    %{widget: put_informed_stations(widget, ["Downtown Crossing"])}
  end

  defp setup_location_context(%{widget: widget}) do
    %{widget: widget}
    |> setup_home_stop()
    |> setup_tagged_stop_sequences()
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

  # We can't build disruption diagrams for some of these alert scenarios.
  # Prevent `ReconstructedAlert.serialize` from filling the console with log noise when this happens.
  defp fake_log(_message), do: nil

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
          ie(route: "Red", route_type: 1, stop: "place-dwnxg"),
          ie(route: "Orange", route_type: 1, stop: "place-dwnxg")
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
        |> put_tagged_stop_sequences(%{
          "Orange" => [
            [
              "place-ogmnl",
              "place-dwnxg",
              "place-chncl",
              "place-forhl"
            ]
          ]
        })
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
        |> put_tagged_stop_sequences(%{
          "Orange" => [
            [
              "place-ogmnl",
              "place-dwnxg",
              "place-chncl",
              "place-forhl"
            ]
          ]
        })
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)

      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
      assert :reconstructed_takeover == WidgetInstance.widget_type(widget)
    end

    test "returns :paged_main_content_left for a takeover when paired with CR widget", %{
      widget: widget
    } do
      widget =
        widget
        |> put_home_stop(PreFare, "place-forhl")
        |> put_informed_entities([ie(stop: "place-chncl"), ie(stop: "place-forhl")])
        |> put_effect(:shuttle)
        |> put_tagged_stop_sequences(%{
          "Orange" => [
            [
              "place-ogmnl",
              "place-dwnxg",
              "place-chncl",
              "place-forhl"
            ]
          ]
        })
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)
        |> put_pair_with_cr_widget(true)

      assert [1] == WidgetInstance.priority(widget)
      assert [:paged_main_content_left] == WidgetInstance.slot_names(widget)
      assert :single_screen_alert == WidgetInstance.widget_type(widget)
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
        |> put_tagged_stop_sequences(%{
          "Orange" => [
            [
              "place-ogmnl",
              "place-dwnxg",
              "place-chncl",
              "place-forhl"
            ]
          ]
        })
        |> put_is_terminal_station(true)

      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
      assert :reconstructed_large_alert == WidgetInstance.widget_type(widget)
    end

    test "returns :paged_main_content_left for full screen single platform closures", %{
      widget: widget
    } do
      widget =
        widget
        |> put_home_stop(PreFare, "place-forhl")
        |> put_effect(:station_closure)
        |> put_is_full_screen(true)

      assert [1] == WidgetInstance.priority(widget)
      assert [:paged_main_content_left] == WidgetInstance.slot_names(widget)
      assert :single_screen_alert == WidgetInstance.widget_type(widget)
    end
  end

  describe "serialize_dual_screen_alert/1 single line station" do
    setup @one_line_station_alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1),
          ie(stop: "place-welln", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains to Forest Hills",
        location: "No Orange Line trains between Malden Center and Wellington",
        cause: nil,
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 5:00 am",
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        endpoints: {"Malden Center", "Wellington"},
        disruption_diagram: %{
          current_station_slot_index: 1,
          effect: :suspension,
          effect_region_slot_index_range: {1, 2},
          line: :orange,
          slots: [
            %{label_id: "place-ogmnl", type: :terminal},
            %{label: %{abbrev: "Malden Ctr", full: "Malden Center"}, show_symbol: true},
            %{label: %{abbrev: "Wellington", full: "Wellington"}, show_symbol: true},
            %{label_id: "place-astao", type: :terminal}
          ]
        },
        is_transfer_station: false,
        region: :boundary
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles shuttle", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-welln")
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1),
          ie(stop: "place-astao", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains to Forest Hills",
        location: "Shuttle buses between Wellington and Assembly",
        cause: nil,
        effect: :shuttle,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 5:00 am",
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        endpoints: {"Wellington", "Assembly"},
        region: :boundary,
        is_transfer_station: false,
        disruption_diagram: %{
          current_station_slot_index: 2,
          effect: :shuttle,
          effect_region_slot_index_range: {2, 3},
          line: :orange,
          slots: [
            %{label_id: "place-ogmnl", type: :terminal},
            %{label: %{abbrev: "Malden Ctr", full: "Malden Center"}, show_symbol: true},
            %{label: %{abbrev: "Wellington", full: "Wellington"}, show_symbol: true},
            %{label_id: "place-astao", type: :terminal}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "Station closed",
        location: %ScreensConfig.V2.FreeTextLine{
          icon: nil,
          text: ["Orange Line trains skip ", %{format: :nowrap, text: "Malden Center"}]
        },
        cause: nil,
        effect: :station_closure,
        remedy: "Seek alternate route",
        updated_at: "Friday, 5:00 am",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        other_closures: ["Malden Center"],
        disruption_diagram: %{
          effect: :station_closure,
          closed_station_slot_indices: [1],
          line: :orange,
          current_station_slot_index: 1,
          slots: [
            %{type: :terminal, label_id: "place-ogmnl"},
            %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
            %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
            %{type: :terminal, label_id: "place-astao"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-welln")
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1),
          ie(stop: "place-astao", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains to Forest Hills",
        location: "No Orange Line trains between Wellington and Assembly",
        cause: :construction,
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 5:00 am",
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        endpoints: {"Wellington", "Assembly"},
        disruption_diagram: %{
          current_station_slot_index: 2,
          effect: :suspension,
          effect_region_slot_index_range: {2, 3},
          line: :orange,
          slots: [
            %{label_id: "place-ogmnl", type: :terminal},
            %{label: %{abbrev: "Malden Ctr", full: "Malden Center"}, show_symbol: true},
            %{label: %{abbrev: "Wellington", full: "Wellington"}, show_symbol: true},
            %{label_id: "place-astao", type: :terminal}
          ]
        },
        is_transfer_station: false,
        region: :boundary
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles terminal boundary suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", direction_id: 1, route_type: 1),
          ie(stop: "place-mlmnl", route: "Orange", direction_id: 1, route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "No Orange Line trains between Oak Grove and Malden Center",
        cause: nil,
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 5:00 am",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        endpoints: {"Oak Grove", "Malden Center"},
        disruption_diagram: %{
          effect: :suspension,
          effect_region_slot_index_range: {0, 1},
          line: :orange,
          current_station_slot_index: 1,
          slots: [
            %{type: :terminal, label_id: "place-ogmnl"},
            %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
            %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
            %{type: :terminal, label_id: "place-astao"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles terminal boundary shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", direction_id: 1, route_type: 1),
          ie(stop: "place-mlmnl", route: "Orange", direction_id: 1, route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_terminal_station(true)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: "Shuttle buses replace Orange Line trains between Oak Grove and Malden Center",
        cause: nil,
        effect: :shuttle,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 5:00 am",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        endpoints: {"Oak Grove", "Malden Center"},
        disruption_diagram: %{
          effect: :shuttle,
          effect_region_slot_index_range: {0, 1},
          line: :orange,
          current_station_slot_index: 1,
          slots: [
            %{type: :terminal, label_id: "place-ogmnl"},
            %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
            %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
            %{type: :terminal, label_id: "place-astao"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end
  end

  describe "serialize_fullscreen_alert/1 one line" do
    setup @one_line_station_alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles boundary suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", route_type: 1, direction_id: 1),
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1, direction_id: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains to Oak Grove",
        location: "No Orange Line trains between Oak Grove and Malden Center",
        cause: nil,
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 5:00 am",
        region: :boundary,
        endpoints: {"Oak Grove", "Malden Center"},
        is_transfer_station: false,
        disruption_diagram: %{
          effect: :suspension,
          effect_region_slot_index_range: {0, 1},
          line: :orange,
          current_station_slot_index: 1,
          slots: [
            %{type: :terminal, label_id: "place-ogmnl"},
            %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
            %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
            %{type: :terminal, label_id: "place-astao"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles boundary shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-ogmnl", route: "Orange", route_type: 1, direction_id: 1),
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1, direction_id: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains to Oak Grove",
        location: "Shuttle buses between Oak Grove and Malden Center",
        cause: nil,
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :shuttle,
        remedy: "Use shuttle bus",
        updated_at: "Friday, 5:00 am",
        region: :boundary,
        endpoints: {"Oak Grove", "Malden Center"},
        is_transfer_station: false,
        disruption_diagram: %{
          effect: :shuttle,
          effect_region_slot_index_range: {0, 1},
          line: :orange,
          current_station_slot_index: 1,
          slots: [
            %{type: :terminal, label_id: "place-ogmnl"},
            %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
            %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
            %{type: :terminal, label_id: "place-astao"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles moderate delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_severity(5)
        |> put_alert_header("Delays are happening")
        |> put_is_full_screen(true)

      expected = %{
        issue: "Trains may be delayed up to 20 minutes",
        cause: nil,
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 5:00 am",
        region: :here
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles severe delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_severity(10)
        |> put_is_full_screen(true)
        |> put_alert_header("Delays are happening")

      expected = %{
        issue: "Trains may be delayed over 60 minutes",
        cause: nil,
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 5:00 am",
        region: :here
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles directional delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1, direction_id: 0)
        ])
        |> put_cause(:unknown)
        |> put_severity(5)
        |> put_alert_header("Delays are happening")
        |> put_is_full_screen(true)

      expected = %{
        issue: "Trains may be delayed up to 20 minutes",
        cause: nil,
        routes: [%{headsign: "Forest Hills", route_id: "Orange", svg_name: "ol-forest-hills"}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 5:00 am",
        region: :here
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)
        |> put_severity(10)
        |> put_is_full_screen(true)
        |> put_alert_header("Delays are happening")

      expected = %{
        issue: "Trains may be delayed over 60 minutes",
        cause: :construction,
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 5:00 am",
        region: :here
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles downstream delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-swnxg", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_severity(10)
        |> put_is_full_screen(true)
        |> put_alert_header("Delays are happening")

      expected = %{
        issue: "Trains may be delayed over 60 minutes",
        cause: nil,
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :delay,
        remedy: "Delays are happening",
        updated_at: "Friday, 5:00 am",
        region: :outside
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles downstream shuttle", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1),
          ie(stop: "place-astao", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: nil,
        cause: nil,
        routes: [%{headsign: "Forest Hills", route_id: "Orange", svg_name: "ol-forest-hills"}],
        effect: :shuttle,
        remedy: "Shuttle buses available",
        updated_at: "Friday, 5:00 am",
        region: :outside,
        endpoints: {"Wellington", "Assembly"},
        is_transfer_station: false,
        disruption_diagram: %{
          current_station_slot_index: 1,
          effect: :shuttle,
          effect_region_slot_index_range: {2, 3},
          line: :orange,
          slots: [
            %{label_id: "place-ogmnl", type: :terminal},
            %{label: %{abbrev: "Malden Ctr", full: "Malden Center"}, show_symbol: true},
            %{label: %{abbrev: "Wellington", full: "Wellington"}, show_symbol: true},
            %{label_id: "place-astao", type: :terminal}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles downstream suspension", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1),
          ie(stop: "place-astao", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No trains",
        location: nil,
        cause: nil,
        routes: [%{headsign: "Forest Hills", route_id: "Orange", svg_name: "ol-forest-hills"}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 5:00 am",
        region: :outside,
        endpoints: {"Wellington", "Assembly"},
        is_transfer_station: false,
        disruption_diagram: %{
          effect: :suspension,
          effect_region_slot_index_range: {2, 3},
          line: :orange,
          current_station_slot_index: 1,
          slots: [
            %{type: :terminal, label_id: "place-ogmnl"},
            %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
            %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
            %{type: :terminal, label_id: "place-astao"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles platform closure at home station", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-portr")
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-portr", route: "Red", route_type: 1),
          ie(stop: "70065", route: "Red", route_type: 1)
        ])
        |> put_tagged_stop_sequences(%{
          "Red" => [["place-portr", "place-asmnl"]]
        })
        |> put_cause(:unknown)
        |> put_is_full_screen(true)
        |> put_alert_header("Test Alert")
        |> put_routes_at_stop([
          %{
            route_id: "Red",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          }
        ])

      expected = %{
        issue: nil,
        remedy: nil,
        remedy_bold: "Test Alert",
        location: nil,
        cause: nil,
        routes: [%{route_id: "Red", svg_name: "rl"}],
        effect: :station_closure,
        updated_at: "Friday, 5:00 am",
        region: :here
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles downstream platform closure", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-asmnl")
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-portr", route: "Red", route_type: 1),
          ie(stop: "70065", route: "Red", route_type: 1)
        ])
        |> put_tagged_stop_sequences(%{
          "Red" => [["place-portr", "place-asmnl"]]
        })
        |> put_cause(:unknown)
        |> put_is_full_screen(true)
        |> put_alert_header("Test Alert")
        |> put_routes_at_stop([
          %{
            route_id: "Red",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          }
        ])

      expected = %{
        issue: nil,
        remedy: nil,
        remedy_bold: "Test Alert",
        location: nil,
        cause: nil,
        routes: [%{route_id: "Red", svg_name: "rl-alewife", headsign: "Alewife"}],
        effect: :station_closure,
        updated_at: "Friday, 5:00 am",
        region: :outside
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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
        issue: nil,
        unaffected_routes: [%{route_id: "Red", svg_name: "rl"}],
        cause: nil,
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :station_closure,
        updated_at: "Friday, 5:00 am",
        region: :here,
        disruption_diagram: %{
          effect: :station_closure,
          closed_station_slot_indices: [3],
          line: :orange,
          current_station_slot_index: 3,
          slots: [
            %{type: :arrow, label_id: "place-ogmnl"},
            %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
            %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
            %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
            %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
            %{type: :arrow, label_id: "place-forhl"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles :inside suspension on 1 line", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-chncl", route: "Orange", route_type: 1),
          ie(stop: "place-dwnxg", route: "Orange", route_type: 1),
          ie(stop: "place-state", route: "Orange", route_type: 1),
          ie(stop: "place-haecl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        cause: nil,
        effect: :suspension,
        endpoints: {"Haymarket", "Chinatown"},
        is_transfer_station: true,
        issue: "No Orange Line trains",
        location: "No Orange Line trains between Haymarket and Chinatown",
        region: :here,
        remedy: "Seek alternate route",
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        updated_at: "Friday, 5:00 am",
        disruption_diagram: %{
          current_station_slot_index: 3,
          effect: :suspension,
          effect_region_slot_index_range: {1, 4},
          line: :orange,
          slots: [
            %{label_id: "place-ogmnl", type: :terminal},
            %{label: %{abbrev: "Haymarket", full: "Haymarket"}, show_symbol: true},
            %{label: %{abbrev: "State", full: "State"}, show_symbol: true},
            %{label: %{abbrev: "Downt'n Xng", full: "Downtown Crossing"}, show_symbol: true},
            %{label: %{abbrev: "Chinatown", full: "Chinatown"}, show_symbol: true},
            %{label_id: "place-forhl", type: :terminal}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles :inside shuttle on 1 line", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-state", route: "Orange", route_type: 1),
          ie(stop: "place-dwnxg", route: "Orange", route_type: 1),
          ie(stop: "place-chncl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        issue: "No Orange Line trains",
        remedy: "Use shuttle bus",
        cause: nil,
        location: "Shuttle buses between State and Chinatown",
        routes: [%{route_id: "Orange", svg_name: "ol"}],
        effect: :shuttle,
        updated_at: "Friday, 5:00 am",
        region: :here,
        endpoints: {"State", "Chinatown"},
        is_transfer_station: true,
        disruption_diagram: %{
          current_station_slot_index: 3,
          effect: :shuttle,
          effect_region_slot_index_range: {2, 4},
          line: :orange,
          slots: [
            %{label_id: "place-ogmnl", type: :terminal},
            %{label: %{abbrev: "Haymarket", full: "Haymarket"}, show_symbol: true},
            %{label: %{abbrev: "State", full: "State"}, show_symbol: true},
            %{label: %{abbrev: "Downt'n Xng", full: "Downtown Crossing"}, show_symbol: true},
            %{label: %{abbrev: "Chinatown", full: "Chinatown"}, show_symbol: true},
            %{label_id: "place-forhl", type: :terminal}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles multi line delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Orange", route_type: 1),
          ie(stop: "place-dwnxg", route: "Red", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_severity(5)
        |> put_is_full_screen(true)

      expected = %{
        issue: "Trains may be delayed up to 20 minutes",
        cause: nil,
        routes: [],
        effect: :delay,
        remedy: nil,
        updated_at: "Friday, 5:00 am",
        region: :here
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end
  end

  describe "serialize_inside_flex_alert/1" do
    setup @alert_widget_context_setup_group ++ [:setup_active_period]

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

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end
  end

  describe "serialize_outside_alert/1" do
    setup @one_line_station_alert_widget_context_setup_group ++ [:setup_active_period]

    test "handles downstream suspension at one stop", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-welln", direction_id: 1, route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Oak Grove trains",
        location: "at Wellington",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles downstream suspension range", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1),
          ie(stop: "place-astao", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No trains",
        location: "between Wellington and Assembly",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles downstream suspension range, one direction only", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-welln", direction_id: 1, route: "Orange", route_type: 1),
          ie(stop: "place-astao", direction_id: 1, route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Oak Grove trains",
        location: "between Wellington and Assembly",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles shuttle at one stop", %{widget: widget} do
      widget =
        widget
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-welln", direction_id: 1, route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)

      expected = %{
        issue: "No Oak Grove trains",
        location: "at Wellington",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :shuttle,
        urgent: false,
        region: :outside,
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles full station closure", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_informed_stations(["Wellington"])

      expected = %{
        issue: "Trains will bypass Wellington",
        location: "",
        cause: "",
        routes: [
          %{color: :orange, text: "ORANGE LINE", type: :text}
        ],
        effect: :station_closure,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles platform closure", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-asmnl")
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-portr", route: "Red", route_type: 1),
          ie(stop: "70065", route: "Red", route_type: 1)
        ])
        |> put_tagged_stop_sequences(%{
          "Red" => [["place-portr", "place-asmnl"]]
        })
        |> put_cause(:unknown)
        |> put_informed_stations(["Porter"])
        |> put_all_platforms_at_informed_station([
          %{id: "70065", platform_name: "Ashmont/Braintree"},
          %{id: "70066", platform_name: "Alewife"}
        ])

      expected = %{
        issue: "Bypassing Ashmont/Braintree platform at Porter",
        location: "",
        cause: nil,
        routes: [
          %{color: :red, text: "RED LINE", type: :text}
        ],
        effect: :fallback,
        urgent: false,
        region: :outside,
        remedy: nil
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1)
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
        remedy: ""
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "handles alert with cause", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)
        |> put_informed_stations(["Wellington"])

      expected = %{
        issue: "Trains will bypass Wellington",
        location: "",
        cause: "due to construction",
        routes: [
          %{color: :orange, text: "ORANGE LINE", type: :text}
        ],
        effect: :station_closure,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "two screen fallback layout for an alert that violates assumptions (suspension that's only 1 stop)",
         %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_alert_header("Simulation of PIO text")
        |> put_informed_entities([
          ie(stop: "place-mlmnl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        cause: nil,
        effect: :suspension,
        issue: "No trains",
        location: "Simulation of PIO text",
        remedy: "Seek alternate route",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        updated_at: "Friday, 5:00 am"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "one screen fallback layout for an alert that violates assumptions (suspension that's only 1 stop)",
         %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_alert_header("Simulation of PIO text")
        |> put_informed_entities([
          ie(stop: "place-welln", route: "Orange", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      expected = %{
        cause: nil,
        effect: :suspension,
        issue: nil,
        location: nil,
        remedy: nil,
        routes: [%{headsign: "Forest Hills", route_id: "Orange", svg_name: "ol-forest-hills"}],
        updated_at: "Friday, 5:00 am",
        region: :outside,
        remedy_bold: "Simulation of PIO text"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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
          ie(stop: "place-spmnl", route: "Green-D", route_type: 0),
          ie(stop: "place-spmnl", route: "Green-E", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_tagged_stop_sequences(%{
          "Green-D" => [
            [
              "place-spmnl",
              "place-north",
              "place-haecl",
              "place-gover"
            ]
          ],
          "Green-E" => [
            [
              "place-spmnl",
              "place-north",
              "place-haecl",
              "place-gover"
            ]
          ]
        })
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
        location: "between North Station and Science Park/West End",
        cause: "",
        routes: [%{color: :green, text: "GREEN LINE", type: :text}],
        effect: :shuttle,
        urgent: false,
        region: :outside,
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "gets correct destination for RL alert affecting trunk and a whole branch", %{
      widget: widget
    } do
      widget =
        widget
        |> put_home_stop(PreFare, "place-portr")
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-andrw", route: "Red", route_type: 1),
          ie(stop: "place-asmnl", route: "Red", route_type: 1),
          ie(stop: "place-brdwy", route: "Red", route_type: 1),
          ie(stop: "place-fldcr", route: "Red", route_type: 1),
          ie(stop: "place-jfk", route: "Red", route_type: 1),
          ie(stop: "place-shmnl", route: "Red", route_type: 1),
          ie(stop: "place-smmnl", route: "Red", route_type: 1)
        ])
        |> put_tagged_stop_sequences(%{
          "Red" => [
            [
              "place-alfcl",
              "place-davis",
              "place-portr",
              "place-harsq",
              "place-cntsq",
              "place-knncl",
              "place-chmnl",
              "place-pktrm",
              "place-dwnxg",
              "place-sstat",
              "place-brdwy",
              "place-andrw",
              "place-jfk",
              "place-nqncy",
              "place-wlsta",
              "place-qnctr",
              "place-qamnl",
              "place-brntn"
            ],
            [
              "place-alfcl",
              "place-davis",
              "place-portr",
              "place-harsq",
              "place-cntsq",
              "place-knncl",
              "place-chmnl",
              "place-pktrm",
              "place-dwnxg",
              "place-sstat",
              "place-brdwy",
              "place-andrw",
              "place-jfk",
              "place-shmnl",
              "place-fldcr",
              "place-smmnl",
              "place-asmnl"
            ]
          ]
        })
        |> put_routes_at_stop([
          %{
            type: :subway,
            route_id: "Red",
            short_name: "",
            active?: true,
            long_name: "Red Line",
            direction_destinations: ["Ashmont/Braintree", "Alewife"]
          }
        ])
        |> put_is_full_screen(true)

      expected = %{
        cause: nil,
        location: nil,
        effect: :shuttle,
        issue: "No trains",
        remedy: "Shuttle buses available",
        updated_at: "Friday, 5:00 am",
        region: :outside,
        routes: [
          %{headsign: "Ashmont", route_id: "Red", svg_name: "rl-ashmont"},
          %{headsign: "Braintree", route_id: "Red", svg_name: "rl-braintree"}
        ],
        endpoints: {"Broadway", "Ashmont"},
        is_transfer_station: false,
        disruption_diagram: %{
          line: :red,
          effect: :shuttle,
          slots: [
            %{type: :terminal, label_id: "place-alfcl"},
            %{label: %{full: "Davis", abbrev: "Davis"}, show_symbol: true},
            %{label: %{full: "Porter", abbrev: "Porter"}, show_symbol: true},
            %{label: %{full: "Harvard", abbrev: "Harvard"}, show_symbol: true},
            %{label: %{full: "Central", abbrev: "Central"}, show_symbol: true},
            %{
              label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
              show_symbol: false
            },
            %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
            %{label: %{full: "Broadway", abbrev: "Broadway"}, show_symbol: true},
            %{label: %{full: "Andrew", abbrev: "Andrew"}, show_symbol: true},
            %{label: %{full: "JFK/UMass", abbrev: "JFK/UMass"}, show_symbol: true},
            %{label: %{full: "Savin Hill", abbrev: "Savin Hill"}, show_symbol: true},
            %{
              label: %{full: "Fields Corner", abbrev: "Fields Cnr"},
              show_symbol: true
            },
            %{label: %{full: "Shawmut", abbrev: "Shawmut"}, show_symbol: true},
            %{type: :terminal, label_id: "place-asmnl"}
          ],
          current_station_slot_index: 2,
          effect_region_slot_index_range: {7, 13}
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "gets correct destination for RL alert affecting one branch starting at JFK", %{
      widget: widget
    } do
      widget =
        widget
        |> put_home_stop(PreFare, "place-portr")
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-asmnl", route: "Red", route_type: 1),
          ie(stop: "place-fldcr", route: "Red", route_type: 1),
          ie(stop: "place-jfk", route: "Red", route_type: 1),
          ie(stop: "place-shmnl", route: "Red", route_type: 1),
          ie(stop: "place-smmnl", route: "Red", route_type: 1)
        ])
        |> put_tagged_stop_sequences(%{
          "Red" => [
            [
              "place-alfcl",
              "place-davis",
              "place-portr",
              "place-harsq",
              "place-cntsq",
              "place-knncl",
              "place-chmnl",
              "place-pktrm",
              "place-dwnxg",
              "place-sstat",
              "place-brdwy",
              "place-andrw",
              "place-jfk",
              "place-nqncy",
              "place-wlsta",
              "place-qnctr",
              "place-qamnl",
              "place-brntn"
            ],
            [
              "place-alfcl",
              "place-davis",
              "place-portr",
              "place-harsq",
              "place-cntsq",
              "place-knncl",
              "place-chmnl",
              "place-pktrm",
              "place-dwnxg",
              "place-sstat",
              "place-brdwy",
              "place-andrw",
              "place-jfk",
              "place-shmnl",
              "place-fldcr",
              "place-smmnl",
              "place-asmnl"
            ]
          ]
        })
        |> put_routes_at_stop([
          %{
            type: :subway,
            route_id: "Red",
            short_name: "",
            active?: true,
            long_name: "Red Line",
            direction_destinations: ["Ashmont/Braintree", "Alewife"]
          }
        ])
        |> put_is_full_screen(true)

      expected = %{
        cause: nil,
        location: nil,
        effect: :shuttle,
        issue: "No trains",
        remedy: "Shuttle buses available",
        updated_at: "Friday, 5:00 am",
        region: :outside,
        routes: [
          %{headsign: "Ashmont", route_id: "Red", svg_name: "rl-ashmont"}
        ],
        endpoints: {"JFK/UMass", "Ashmont"},
        is_transfer_station: false,
        disruption_diagram: %{
          line: :red,
          effect: :shuttle,
          slots: [
            %{type: :terminal, label_id: "place-alfcl"},
            %{label: %{full: "Davis", abbrev: "Davis"}, show_symbol: true},
            %{label: %{full: "Porter", abbrev: "Porter"}, show_symbol: true},
            %{label: %{full: "Harvard", abbrev: "Harvard"}, show_symbol: true},
            %{label: %{full: "Central", abbrev: "Central"}, show_symbol: true},
            %{
              label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
              show_symbol: false
            },
            %{label: %{full: "Andrew", abbrev: "Andrew"}, show_symbol: true},
            %{label: %{full: "JFK/UMass", abbrev: "JFK/UMass"}, show_symbol: true},
            %{label: %{full: "Savin Hill", abbrev: "Savin Hill"}, show_symbol: true},
            %{
              label: %{full: "Fields Corner", abbrev: "Fields Cnr"},
              show_symbol: true
            },
            %{label: %{full: "Shawmut", abbrev: "Shawmut"}, show_symbol: true},
            %{type: :terminal, label_id: "place-asmnl"}
          ],
          current_station_slot_index: 2,
          effect_region_slot_index_range: {7, 11}
        }
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "gets correct destination for RL alert affecting both branches", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-portr")
        |> put_effect(:shuttle)
        |> put_alert_header("Simulation of PIO text")
        |> put_informed_entities([
          ie(stop: "place-nqncy", route: "Red", route_type: 1),
          ie(stop: "place-asmnl", route: "Red", route_type: 1),
          ie(stop: "place-fldcr", route: "Red", route_type: 1),
          ie(stop: "place-jfk", route: "Red", route_type: 1),
          ie(stop: "place-shmnl", route: "Red", route_type: 1),
          ie(stop: "place-smmnl", route: "Red", route_type: 1)
        ])
        |> put_tagged_stop_sequences(%{
          "Red" => [
            [
              "place-alfcl",
              "place-davis",
              "place-portr",
              "place-harsq",
              "place-cntsq",
              "place-knncl",
              "place-chmnl",
              "place-pktrm",
              "place-dwnxg",
              "place-sstat",
              "place-brdwy",
              "place-andrw",
              "place-jfk",
              "place-nqncy",
              "place-wlsta",
              "place-qnctr",
              "place-qamnl",
              "place-brntn"
            ],
            [
              "place-alfcl",
              "place-davis",
              "place-portr",
              "place-harsq",
              "place-cntsq",
              "place-knncl",
              "place-chmnl",
              "place-pktrm",
              "place-dwnxg",
              "place-sstat",
              "place-brdwy",
              "place-andrw",
              "place-jfk",
              "place-shmnl",
              "place-fldcr",
              "place-smmnl",
              "place-asmnl"
            ]
          ]
        })
        |> put_routes_at_stop([
          %{
            type: :subway,
            route_id: "Red",
            short_name: "",
            active?: true,
            long_name: "Red Line",
            direction_destinations: ["Ashmont/Braintree", "Alewife"]
          }
        ])
        |> put_is_full_screen(true)

      expected = %{
        cause: "",
        effect: :shuttle,
        issue: nil,
        location: nil,
        remedy: nil,
        routes: [
          %{headsign: "Ashmont", route_id: "Red", svg_name: "rl-ashmont"},
          %{headsign: "Braintree", route_id: "Red", svg_name: "rl-braintree"}
        ],
        updated_at: "Friday, 5:00 am",
        region: :outside,
        remedy_bold: "Simulation of PIO text"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end
  end

  describe "endpoint reversal" do
    setup [:setup_screen_config, :setup_now, :setup_active_period]

    test "reverses endpoints for BL alerts", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-mvbcl")
        |> put_effect(:shuttle)
        |> put_informed_entities([
          ie(stop: "place-orhte", route: "Blue", route_type: 0),
          ie(stop: "place-wimnl", route: "Blue", route_type: 0),
          ie(stop: "place-aport", route: "Blue", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_tagged_stop_sequences(%{
          "Blue" => [
            [
              "place-wondl",
              "place-rbmnl",
              "place-bmmnl",
              "place-sdmnl",
              "place-orhte",
              "place-wimnl",
              "place-aport",
              "place-mvbcl",
              "place-aqucl",
              "place-state",
              "place-gover",
              "place-bomnl"
            ]
          ]
        })
        |> put_routes_at_stop([
          %{
            route_id: "Blue",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          }
        ])

      expected = %{
        issue: "No trains",
        location: "between Airport and Orient Heights",
        cause: "",
        routes: [%{color: :blue, text: "BLUE LINE", type: :text}],
        effect: :shuttle,
        urgent: false,
        region: :outside,
        remedy: "Use shuttle bus"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "reverses endpoints for GL trunk alert", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-gover")
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-pktrm", route: "Green-B", route_type: 0),
          ie(stop: "place-pktrm", route: "Green-C", route_type: 0),
          ie(stop: "place-pktrm", route: "Green-D", route_type: 0),
          ie(stop: "place-pktrm", route: "Green-E", route_type: 0),
          ie(stop: "place-boyls", route: "Green-B", route_type: 0),
          ie(stop: "place-boyls", route: "Green-C", route_type: 0),
          ie(stop: "place-boyls", route: "Green-D", route_type: 0),
          ie(stop: "place-boyls", route: "Green-E", route_type: 0),
          ie(stop: "place-armnl", route: "Green-B", route_type: 0),
          ie(stop: "place-armnl", route: "Green-C", route_type: 0),
          ie(stop: "place-armnl", route: "Green-D", route_type: 0),
          ie(stop: "place-armnl", route: "Green-E", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_tagged_stop_sequences(%{
          "Green-B" => [
            [
              "place-haecl",
              "place-gover",
              "place-pktrm",
              "place-boyls",
              "place-armnl"
            ]
          ],
          "Green-C" => [
            [
              "place-haecl",
              "place-gover",
              "place-pktrm",
              "place-boyls",
              "place-armnl"
            ]
          ],
          "Green-D" => [
            [
              "place-haecl",
              "place-gover",
              "place-pktrm",
              "place-boyls",
              "place-armnl"
            ]
          ],
          "Green-E" => [
            [
              "place-haecl",
              "place-gover",
              "place-pktrm",
              "place-boyls",
              "place-armnl"
            ]
          ]
        })
        |> put_routes_at_stop([
          %{
            route_id: "Green-B",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          },
          %{
            route_id: "Green-C",
            active?: true,
            direction_destinations: nil,
            long_name: nil,
            short_name: nil,
            type: :subway
          },
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
        location: "between Arlington and Park Street",
        cause: "",
        routes: [%{color: :green, text: "GREEN LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "reverses endpoints for GL western branch alert", %{widget: widget} do
      widget =
        widget
        |> put_home_stop(PreFare, "place-symcl")
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-mfa", route: "Green-E", route_type: 0),
          ie(stop: "place-lngmd", route: "Green-E", route_type: 0),
          ie(stop: "place-brmnl", route: "Green-E", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_tagged_stop_sequences(%{
          "Green-E" => [
            [
              "place-symcl",
              "place-nuniv",
              "place-mfa",
              "place-lngmd",
              "place-brmnl"
            ]
          ]
        })
        |> put_routes_at_stop([
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
        location: "between Brigham Circle and Museum of Fine Arts",
        cause: "",
        routes: [%{color: :green, text: "GREEN LINE", type: :text, branches: ["E"]}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
    end

    test "does not reverse endpoints for GLX alert", %{
      widget: widget
    } do
      widget =
        widget
        |> put_home_stop(PreFare, "place-esomr")
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-balsq", route: "Green-E", route_type: 0),
          ie(stop: "place-mgngl", route: "Green-E", route_type: 0),
          ie(stop: "place-gilmn", route: "Green-E", route_type: 0)
        ])
        |> put_cause(:unknown)
        |> put_tagged_stop_sequences(%{
          "Green-E" => [
            [
              "place-balsq",
              "place-mgngl",
              "place-gilmn",
              "place-esomr"
            ]
          ]
        })
        |> put_routes_at_stop([
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
        location: "between Ball Square and Gilman Square",
        cause: "",
        routes: [%{color: :green, text: "GREEN LINE", type: :text, branches: ["E"]}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected == ReconstructedAlert.serialize(widget, &fake_log/1)
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

    test "returns [1] when alert is urgent", %{widget: widget} do
      widget =
        widget
        |> put_effect(:suspension)
        |> put_informed_entities([
          ie(stop: "place-dwnxg", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_is_full_screen(true)

      assert [1] == WidgetInstance.audio_sort_key(widget)
    end

    test "returns [1, 2] when alert is not urgent", %{widget: widget} do
      widget =
        widget
        |> put_effect(:station_closure)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red", route_type: 1),
          ie(stop: "place-alfcl", route: "Orange", route_type: 1)
        ])
        |> put_cause(:construction)

      assert [1, 2] == WidgetInstance.audio_sort_key(widget)
    end

    test "returns [1, 1] when alert effect is :delay", %{widget: widget} do
      widget =
        widget
        |> put_effect(:delay)
        |> put_informed_entities([
          ie(stop: "place-alfcl", route: "Red", route_type: 1)
        ])
        |> put_cause(:unknown)
        |> put_alert_header("Test Alert")

      assert [1, 1] == WidgetInstance.audio_sort_key(widget)
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
            struct(PreFare, %{
              reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}
            })
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
      tagged_station_sequences = %{"Orange" => [Stop.get_route_stop_sequence("Orange")]}
      station_sequences = RoutePattern.untag_stop_sequences(tagged_station_sequences)

      fetch_alerts_fn = fn _ -> {:ok, alerts} end
      fetch_stop_name_fn = fn _ -> "Wellington" end

      fetch_location_context_fn = fn _, _, _ ->
        {:ok,
         %LocationContext{
           home_stop: stop_id,
           tagged_stop_sequences: tagged_station_sequences,
           upstream_stops: Stop.upstream_stop_id_set(stop_id, station_sequences),
           downstream_stops: Stop.downstream_stop_id_set(stop_id, station_sequences),
           routes: routes_at_stop,
           alert_route_types: Stop.get_route_type_filter(PreFare, stop_id)
         }}
      end

      fetch_subway_platforms_for_stop_fn = fn _ -> [] end

      alert_widget =
        config
        |> CandidateGenerator.Widgets.ReconstructedAlert.reconstructed_alert_instances(
          now,
          fetch_alerts_fn,
          fetch_stop_name_fn,
          fetch_location_context_fn,
          fetch_subway_platforms_for_stop_fn
        )
        |> List.first()

      # Fullscreen test
      expected = %{
        issue: "No trains",
        location: nil,
        cause: nil,
        routes: [%{headsign: "Forest Hills", route_id: "Orange", svg_name: "ol-forest-hills"}],
        effect: :suspension,
        remedy: "Seek alternate route",
        updated_at: "Friday, 5:14 am",
        region: :outside,
        endpoints: {"North Station", "Back Bay"},
        is_transfer_station: false,
        disruption_diagram: %{
          effect: :suspension,
          effect_region_slot_index_range: {6, 12},
          line: :orange,
          current_station_slot_index: 2,
          slots: [
            %{type: :terminal, label_id: "place-ogmnl"},
            %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
            %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
            %{label: %{full: "Assembly", abbrev: "Assembly"}, show_symbol: true},
            %{label: %{full: "Sullivan Square", abbrev: "Sullivan Sq"}, show_symbol: true},
            %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
            %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
            %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
            %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
            %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
            %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
            %{label: %{full: "Tufts Medical Center", abbrev: "Tufts Med"}, show_symbol: true},
            %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
            %{type: :arrow, label_id: "place-forhl"}
          ]
        }
      }

      assert expected == ReconstructedAlert.serialize(alert_widget, &fake_log/1)

      # Flexzone test
      expected = %{
        issue: "No trains",
        location: "between North Station and Back Bay",
        cause: "",
        routes: [%{color: :orange, text: "ORANGE LINE", type: :text}],
        effect: :suspension,
        urgent: false,
        region: :outside,
        remedy: "Seek alternate route"
      }

      assert expected ==
               ReconstructedAlert.serialize(
                 %{alert_widget | is_full_screen: false},
                 &fake_log/1
               )
    end

    test "handles GL boundary shuttle at Govt Center" do
      stop_id = "place-gover"

      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(PreFare, %{
              reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}
            })
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
      tagged_station_sequences = %{"Green" => [Stop.get_route_stop_sequence("Green")]}
      station_sequences = RoutePattern.untag_stop_sequences(tagged_station_sequences)

      fetch_alerts_fn = fn _ -> {:ok, alerts} end
      fetch_stop_name_fn = fn _ -> "Government Center" end

      fetch_location_context_fn = fn _, _, _ ->
        {:ok,
         %LocationContext{
           home_stop: stop_id,
           tagged_stop_sequences: tagged_station_sequences,
           upstream_stops: Stop.upstream_stop_id_set(stop_id, station_sequences),
           downstream_stops: Stop.downstream_stop_id_set(stop_id, station_sequences),
           routes: routes_at_stop,
           alert_route_types: Stop.get_route_type_filter(PreFare, stop_id)
         }}
      end

      fetch_subway_platforms_for_stop_fn = fn _ -> [] end

      alert_widget =
        config
        |> CandidateGenerator.Widgets.ReconstructedAlert.reconstructed_alert_instances(
          now,
          fetch_alerts_fn,
          fetch_stop_name_fn,
          fetch_location_context_fn,
          fetch_subway_platforms_for_stop_fn
        )
        |> List.first()

      # Fullscreen test
      expected = %{
        cause: nil,
        effect: :shuttle,
        issue: nil,
        location: nil,
        region: :boundary,
        remedy: nil,
        routes: [%{route_id: "Green", svg_name: "gl"}],
        updated_at: "Friday, 2:24 pm",
        remedy_bold:
          "Green Line is replaced by shuttle buses between Government Center and Union Square due to a structural issue with the Government Center Garage. Shuttle buses are not servicing Haymarket Station."
      }

      assert expected == ReconstructedAlert.serialize(alert_widget, &fake_log/1)

      # Flexzone test
      expected = %{
        issue: "No North Station & North trains",
        location: "",
        cause: "",
        routes: [%{color: :green, text: "GREEN LINE", type: :text}],
        effect: :shuttle,
        urgent: true,
        region: :boundary,
        remedy: "Use shuttle bus"
      }

      assert expected ==
               ReconstructedAlert.serialize(
                 %{alert_widget | is_full_screen: false},
                 &fake_log/1
               )
    end
  end
end
