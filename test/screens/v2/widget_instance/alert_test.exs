defmodule Screens.V2.WidgetInstance.AlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{BusEink, BusShelter, GlEink, Solari}
  alias Screens.V2.AlertWidgetInstance
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
    alias Screens.Config.V2.Alerts

    %{
      widget
      | screen: %{
          widget.screen
          | app_params: struct(app_config_module, %{alerts: %Alerts{stop_id: stop_id}})
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

  defp put_app_id(widget, app_id) do
    %{widget | screen: %{widget.screen | app_id: app_id}}
  end

  defp put_effect(widget, effect) do
    %{widget | alert: %{widget.alert | effect: effect}}
  end

  defp put_now(widget, now) do
    %{widget | now: now}
  end

  defp ie(opts) do
    %{stop: opts[:stop], route: opts[:route], route_type: opts[:route_type]}
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

  defp setup_routes(%{widget: widget}) do
    routes = [
      %{route_id: "a", active?: true},
      %{route_id: "b", active?: false},
      %{route_id: "c", active?: true}
    ]

    %{widget: put_routes_at_stop(widget, routes)}
  end

  defp setup_screen_config(%{widget: widget}) do
    %{widget: put_app_id(widget, :bus_shelter_v2)}
  end

  defp setup_now(%{widget: widget}) do
    %{widget: put_now(widget, ~U[2021-01-01T00:00:00Z])}
  end

  defp setup_informed_entities(%{widget: widget}) do
    %{widget: put_informed_entities(widget, [ie(stop: "5")])}
  end

  defp setup_active_period(%{widget: widget}) do
    active_period = [
      {~U[2021-01-01T00:00:00Z], ~U[2021-01-01T22:00:00Z]},
      {~U[2021-01-02T00:00:00Z], ~U[2021-01-02T22:00:00Z]}
    ]

    %{widget: put_active_period(widget, active_period)}
  end

  defp setup_effect(%{widget: widget}) do
    %{widget: put_effect(widget, :stop_closure)}
  end

  # Pass this to `setup` to set up "context" data on the alert widget, without setting up the API alert itself.
  @alert_widget_context_setup_group [
    :setup_home_stop,
    :setup_stop_sequences,
    :setup_routes,
    :setup_screen_config,
    :setup_now
  ]

  # Pass this to `setup` to set up a stop_closure alert that is currently active (just started) and affects the home stop.
  @valid_alert_setup_group @alert_widget_context_setup_group ++
                             [
                               :setup_informed_entities,
                               :setup_active_period,
                               :setup_effect
                             ]

  describe "priority/1" do
    setup @valid_alert_setup_group

    test "returns [1, 2] when slot_names(widget) == [:full_body]", %{widget: widget} do
      assert [1, 2] == AlertWidget.priority(widget)
    end

    test "returns a list of tiebreaker values when widget should be considered for placement", %{
      widget: widget
    } do
      widget = put_effect(widget, :snow_route)

      assert [2 | _] = AlertWidget.priority(widget)
    end

    test "returns :no_render if any of the tiebreaker functions returns :no_render", %{
      widget: widget
    } do
      # Currently active, but happening long enough that we don't want to show it anymore
      active_period = [
        {~U[2020-01-01T00:00:00Z], ~U[2020-01-01T20:00:00Z]},
        {~U[2021-01-01T00:00:00Z], ~U[2021-01-01T20:00:00Z]}
      ]

      widget = put_active_period(widget, active_period)

      assert :no_render == AlertWidget.priority(widget)
    end
  end

  describe "serialize/1" do
    setup @valid_alert_setup_group ++ [:setup_display_values]

    defp setup_display_values(%{widget: widget}) do
      widget = %{widget | alert: %{widget.alert | header: "Stop is closed."}}

      %{widget: widget}
    end

    test "serializes an alert widget", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(route: "a"), ie(route: "b"), ie(route: "c")])

      expected_json_map = %{
        route_pills: [
          %{type: :text, text: "a", color: :yellow},
          %{type: :text, text: "b", color: :yellow},
          %{type: :text, text: "c", color: :yellow}
        ],
        icon: :x,
        header: "Stop Closed",
        body: "Stop is closed.",
        url: "mbta.com/alerts"
      }

      assert expected_json_map == AlertWidget.serialize(widget)
    end

    test "serializes a GL alert widget for alert affecting all branches", %{widget: widget} do
      widget =
        widget
        |> put_informed_entities([
          ie(route: "Green-B"),
          ie(route: "Green-C"),
          ie(route: "Green-D"),
          ie(route: "Green-E")
        ])
        |> put_app_id(:gl_eink_v2)

      expected_json_map = %{
        route_pills: [
          %{type: :text, text: "Green Line", color: :green}
        ],
        icon: :x,
        header: "Stop Closed",
        body: "Stop is closed.",
        url: "mbta.com/alerts"
      }

      assert expected_json_map == AlertWidget.serialize(widget)
    end

    test "serializes a GL alert widget for alert affecting 2 branches", %{widget: widget} do
      widget =
        widget
        |> put_informed_entities([
          ie(route: "Green-B"),
          ie(route: "Green-C")
        ])
        |> put_app_id(:gl_eink_v2)

      expected_json_map = %{
        route_pills: [
          %{type: :text, text: "GL·B", color: :green},
          %{type: :text, text: "GL·C", color: :green}
        ],
        icon: :x,
        header: "Stop Closed",
        body: "Stop is closed.",
        url: "mbta.com/alerts"
      }

      assert expected_json_map == AlertWidget.serialize(widget)
    end

    test "serializes a GL alert widget for alert affecting 1 branches", %{widget: widget} do
      widget =
        widget
        |> put_informed_entities([
          ie(route: "Green-B")
        ])
        |> put_app_id(:gl_eink_v2)

      expected_json_map = %{
        route_pills: [
          %{type: :text, text: "Green Line B", color: :green}
        ],
        icon: :x,
        header: "Stop Closed",
        body: "Stop is closed.",
        url: "mbta.com/alerts"
      }

      assert expected_json_map == AlertWidget.serialize(widget)
    end

    test "converts non-route informed entities to route pills as expected", %{widget: widget} do
      # widget has informed_entities: [%{stop: "5", route: nil, route_type: nil}]

      expected_json_map = %{
        route_pills: [
          %{type: :text, text: "a", color: :yellow},
          %{type: :text, text: "b", color: :yellow},
          %{type: :text, text: "c", color: :yellow}
        ],
        icon: :x,
        header: "Stop Closed",
        body: "Stop is closed.",
        url: "mbta.com/alerts"
      }

      assert expected_json_map == AlertWidget.serialize(widget)
    end

    test "collapses more than 3 route pills to a single mode pill", %{widget: widget} do
      widget =
        widget
        |> put_routes_at_stop([
          %{route_id: "a", active?: true},
          %{route_id: "b", active?: false},
          %{route_id: "c", active?: true},
          %{route_id: "d", active?: true},
          %{route_id: "e", active?: true}
        ])
        |> put_informed_entities([ie(route: "a"), ie(route: "b"), ie(route: "c"), ie(route: "d")])

      expected_json_map = %{
        route_pills: [%{type: :icon, icon: :bus, color: :yellow}],
        icon: :x,
        header: "Stop Closed",
        body: "Stop is closed.",
        url: "mbta.com/alerts"
      }

      assert expected_json_map == AlertWidget.serialize(widget)
    end
  end

  describe "slot_names/1 for bus apps (Bus Shelter and Bus E-Ink)" do
    setup @alert_widget_context_setup_group

    # active | high-impact | informs all routes || full-screen?
    # n      | n           | n                  || n
    # y      | n           | n                  || n
    # n      | y           | n                  || n
    # y      | y           | n                  || n
    # n      | n           | y                  || n
    # y      | n           | y                  || n
    # n      | y           | y                  || n
    # y      | y           | y                  || y

    @bus_slot_names_cases %{
      {false, false, false} => [:medium_left, :medium_right],
      {true, false, false} => [:medium_left, :medium_right],
      {false, true, false} => [:medium_left, :medium_right],
      {true, true, false} => [:medium_left, :medium_right],
      {false, false, true} => [:medium_left, :medium_right],
      {true, false, true} => [:medium_left, :medium_right],
      {false, true, true} => [:medium_left, :medium_right],
      {true, true, true} => [:full_body]
    }

    for {{set_active?, set_high_impact_effect?, set_informs_all_active_routes?},
         expected_slot_names} <- @bus_slot_names_cases do
      false_to_not = fn
        true -> ""
        false -> "not "
      end

      test_description =
        "returns #{inspect(expected_slot_names)} if alert is " <>
          false_to_not.(set_active?) <>
          "active and does " <>
          false_to_not.(set_high_impact_effect?) <>
          "have a high-impact effect and does " <>
          false_to_not.(set_informs_all_active_routes?) <>
          "inform all active routes at home stop"

      test test_description, %{widget: widget} do
        active_period =
          if(unquote(set_active?),
            do: [{~U[2021-01-01T00:00:00Z], ~U[2021-01-01T22:00:00Z]}],
            else: [{~U[2021-01-02T00:00:00Z], ~U[2021-01-02T22:00:00Z]}]
          )

        effect = if(unquote(set_high_impact_effect?), do: :stop_closure, else: :snow_route)

        informed_entities =
          if(unquote(set_informs_all_active_routes?),
            do: [ie(route: "a"), ie(route: "c")],
            else: [ie(route: "a"), ie(route: "b")]
          )

        widget =
          widget
          |> put_active_period(active_period)
          |> put_effect(effect)
          |> put_informed_entities(informed_entities)

        assert unquote(expected_slot_names) == AlertWidget.slot_names(widget)
      end
    end

    test "returns [:medium] for a non-full-screen alert on Bus E-Ink", %{widget: widget} do
      widget =
        widget
        |> put_app_id(:bus_eink_v2)
        |> put_home_stop(BusEink, "5")
        |> put_active_period([{~U[2021-01-02T00:00:00Z], ~U[2021-01-02T22:00:00Z]}])
        |> put_effect(:snow_route)
        |> put_informed_entities([ie(route: "a"), ie(route: "b")])

      assert [:medium] == AlertWidget.slot_names(widget)
    end
  end

  describe "slot_names/1 for Green Line E-Ink app" do
    setup @alert_widget_context_setup_group ++ [:setup_gl_eink_config]

    defp setup_gl_eink_config(%{widget: widget}) do
      widget =
        widget
        |> put_app_id(:gl_eink_v2)
        |> put_home_stop(GlEink, "5")

      %{widget: widget}
    end

    # active | high-impact | location [:inside, :boundary_downstream, :boundary_upstream]  || full-screen?
    # n      | n           | n                                                             || n
    # y      | n           | n                                                             || n
    # n      | y           | n                                                             || n
    # y      | y           | n                                                             || n
    # n      | n           | y                                                             || n
    # y      | n           | y                                                             || n
    # n      | y           | y                                                             || n
    # y      | y           | y                                                             || y

    @gl_slot_names_cases %{
      {false, false, false} => [:medium],
      {true, false, false} => [:medium],
      {false, true, false} => [:medium],
      {true, true, false} => [:medium],
      {false, false, true} => [:medium],
      {true, false, true} => [:medium],
      {false, true, true} => [:medium],
      {true, true, true} => [:full_body_top_screen]
    }

    for {{set_active?, set_high_impact_effect?, set_location_inside_or_boundary?},
         expected_slot_names} <-
          @gl_slot_names_cases do
      false_to_not = fn
        true -> " "
        false -> " not "
      end

      test_description =
        "returns #{inspect(expected_slot_names)} if alert is " <>
          false_to_not.(set_active?) <>
          "active and does" <>
          false_to_not.(set_high_impact_effect?) <>
          "have a high-impact effect and does" <>
          false_to_not.(set_location_inside_or_boundary?) <>
          "contain home stop in informed region"

      test test_description, %{widget: widget} do
        active_period =
          if(unquote(set_active?),
            do: [{~U[2021-01-01T00:00:00Z], ~U[2021-01-01T22:00:00Z]}],
            else: [{~U[2021-01-02T00:00:00Z], ~U[2021-01-02T22:00:00Z]}]
          )

        effect = if(unquote(set_high_impact_effect?), do: :suspension, else: :elevator_closure)

        informed_entities =
          if(unquote(set_location_inside_or_boundary?),
            do: [ie(stop: "4"), ie(stop: "5"), ie(stop: "6")],
            else: [ie(stop: "6"), ie(stop: "7")]
          )

        widget =
          widget
          |> put_active_period(active_period)
          |> put_effect(effect)
          |> put_informed_entities(informed_entities)

        assert unquote(expected_slot_names) == AlertWidget.slot_names(widget)
      end
    end
  end

  describe "active?/2" do
    test "simply calls Alert.happening_now?/1 on the widget's alert", %{widget: widget} do
      yes_happening_now = fn %Alert{id: "123"}, _ -> true end
      not_happening_now = fn %Alert{id: "123"}, _ -> false end

      assert AlertWidget.active?(widget, yes_happening_now)
      assert not AlertWidget.active?(widget, not_happening_now)
    end
  end

  describe "seconds_from_onset/2" do
    test "returns difference in seconds between now and first active period's start time", %{
      widget: widget
    } do
      start = ~U[2021-01-01T00:00:00Z]
      now = ~U[2021-01-01T01:00:00Z]

      widget =
        widget
        |> put_active_period([{start, nil}])
        |> put_now(now)

      expected_seconds_elapsed = 3600

      assert expected_seconds_elapsed == AlertWidget.seconds_from_onset(widget)
    end

    test "returns a negative value if current time is before first active period", %{
      widget: widget
    } do
      start = ~U[2021-01-01T01:00:00Z]
      now = ~U[2021-01-01T00:00:00Z]

      widget =
        widget
        |> put_active_period([{start, nil}])
        |> put_now(now)

      expected_seconds_elapsed = -3600

      assert expected_seconds_elapsed == AlertWidget.seconds_from_onset(widget)
    end
  end

  describe "seconds_to_next_active_period/2" do
    test "returns seconds to start of first active period after current time, if it exists", %{
      widget: widget
    } do
      now = ~U[2021-01-02T01:00:00Z]
      next_start = ~U[2021-01-03T00:00:01Z]

      widget =
        widget
        |> put_active_period([
          {~U[2021-01-01T00:00:00Z], ~U[2021-01-01T23:00:00Z]},
          {~U[2021-01-02T00:00:00Z], ~U[2021-01-02T23:00:00Z]},
          {next_start, ~U[2021-01-03T23:00:00Z]}
        ])
        |> put_now(now)

      expected_seconds_to_next_active_period = 23 * 60 * 60 + 1

      assert expected_seconds_to_next_active_period ==
               AlertWidget.seconds_to_next_active_period(widget)
    end

    test "returns :infinity if no active period starting after current time exists", %{
      widget: widget
    } do
      widget = put_now(widget, ~U[2021-01-02T01:00:00Z])

      # no active period at all
      assert :infinity == AlertWidget.seconds_to_next_active_period(widget)

      # no start date after current time
      widget =
        put_active_period(widget, [
          {nil, ~U[2021-01-01T23:00:00Z]},
          {~U[2021-01-02T00:00:00Z], ~U[2021-01-02T23:00:00Z]}
        ])

      assert :infinity == AlertWidget.seconds_to_next_active_period(widget)
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

  describe "effect/1" do
    test "returns effect from the widget's alert", %{widget: widget} do
      effect = :detour

      widget = put_effect(widget, effect)

      assert effect == AlertWidget.effect(widget)
    end
  end

  describe "tiebreaker_primary_timeframe/1" do
    setup @valid_alert_setup_group

    test "returns 1 for alerts that are active and started less than 4 weeks ago", %{
      widget: widget
    } do
      widget = put_active_period(widget, [{~U[2021-01-01T00:00:00Z], nil}])

      assert 1 == AlertWidget.tiebreaker_primary_timeframe(widget)
    end

    test "returns 2 for alerts that are active and started 4-12 weeks ago", %{widget: widget} do
      widget =
        put_active_period(widget, [
          {~U[2020-11-01T00:00:00Z], ~U[2020-11-01T20:00:00Z]},
          {~U[2021-01-01T00:00:00Z], nil}
        ])

      assert 2 == AlertWidget.tiebreaker_primary_timeframe(widget)
    end

    test "returns 2 for alerts that are inactive and next active period starts in less than 36 hours",
         %{widget: widget} do
      widget =
        put_active_period(widget, [
          {~U[2021-01-02T00:00:00Z], nil}
        ])

      assert 2 == AlertWidget.tiebreaker_primary_timeframe(widget)
    end

    test "returns 3 for alerts that are inactive and next active period starts in 36 hours or more",
         %{widget: widget} do
      widget = put_active_period(widget, [{~U[2021-01-10T00:00:00Z], nil}])

      assert 3 == AlertWidget.tiebreaker_primary_timeframe(widget)
    end

    test "returns 4 for alerts that are active and started 12-24 weeks ago", %{widget: widget} do
      widget =
        put_active_period(widget, [
          {~U[2020-10-01T00:00:00Z], ~U[2020-10-01T20:00:00Z]},
          {~U[2021-01-01T00:00:00Z], nil}
        ])

      assert 4 == AlertWidget.tiebreaker_primary_timeframe(widget)
    end

    test "returns :no_render for active alerts older than 24 weeks", %{widget: widget} do
      widget =
        put_active_period(widget, [
          {~U[2020-05-01T00:00:00Z], ~U[2020-05-01T20:00:00Z]},
          {~U[2021-01-01T00:00:00Z], nil}
        ])

      assert :no_render == AlertWidget.tiebreaker_primary_timeframe(widget)
    end
  end

  describe "tiebreaker_location" do
    setup @valid_alert_setup_group

    test "returns 1 if home stop is inside informed region", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(stop: "5")])

      assert 1 == AlertWidget.tiebreaker_location(widget)
    end

    test "returns 2 if home stop is at the boundary of informed region", %{widget: widget} do
      upstream_boundary_widget = put_informed_entities(widget, [ie(stop: "5"), ie(stop: "4")])

      assert 2 == AlertWidget.tiebreaker_location(upstream_boundary_widget)

      downstream_boundary_widget = put_informed_entities(widget, [ie(stop: "5"), ie(stop: "6")])

      assert 2 == AlertWidget.tiebreaker_location(downstream_boundary_widget)
    end

    test "returns 3 if informed region is downstream of home stop", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(stop: "6")])

      assert 3 == AlertWidget.tiebreaker_location(widget)
    end

    test "returns :no_render if informed region is upstream of home stop or elsewhere", %{
      widget: widget
    } do
      upstream_widget = put_informed_entities(widget, [ie(stop: "4")])

      assert :no_render == AlertWidget.tiebreaker_location(upstream_widget)

      elsewhere_widget = put_informed_entities(widget, [ie(route: "doesnt_serve_this_stop")])

      assert :no_render == AlertWidget.tiebreaker_location(elsewhere_widget)
    end
  end

  describe "tiebreaker_secondary_timeframe/1" do
    setup @valid_alert_setup_group

    test "returns 1 for alerts that are inactive and next active period starts in less than 36 hours",
         %{widget: widget} do
      widget =
        put_active_period(widget, [
          {~U[2021-01-02T00:00:00Z], nil}
        ])

      assert 1 == AlertWidget.tiebreaker_secondary_timeframe(widget)
    end

    test "returns 2 for alerts that are active and started 4-12 weeks ago", %{widget: widget} do
      widget =
        put_active_period(widget, [
          {~U[2020-11-01T00:00:00Z], ~U[2020-11-01T20:00:00Z]},
          {~U[2021-01-01T00:00:00Z], nil}
        ])

      assert 2 == AlertWidget.tiebreaker_secondary_timeframe(widget)
    end

    test "returns 3 in all other cases", %{widget: widget} do
      active_now_widget = put_active_period(widget, [{~U[2021-01-01T00:00:00Z], nil}])

      assert 3 == AlertWidget.tiebreaker_secondary_timeframe(active_now_widget)

      inactive_for_a_while_widget = put_active_period(widget, [{~U[2021-01-10T00:00:00Z], nil}])

      assert 3 == AlertWidget.tiebreaker_secondary_timeframe(inactive_for_a_while_widget)
    end
  end

  describe "tiebreaker_effect" do
    setup @valid_alert_setup_group

    test "returns priority value corresponding to effect, if supported", %{widget: widget} do
      # base widget has stop_closure effect
      assert is_integer(AlertWidget.tiebreaker_effect(widget))

      shuttle_widget = put_effect(widget, :shuttle)

      assert is_integer(AlertWidget.tiebreaker_effect(shuttle_widget))
    end

    test "returns :no_render for unsupported alert effects", %{widget: widget} do
      widget = put_effect(widget, :service_change)

      assert :no_render == AlertWidget.tiebreaker_effect(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string", %{widget: widget} do
      assert %{} == AlertWidget.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{widget: widget} do
      assert [0] == AlertWidget.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{widget: widget} do
      refute AlertWidget.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns AlertView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.AlertView == AlertWidget.audio_view(widget)
    end
  end

  describe "alert_id/1" do
    test "returns alert_id", %{widget: widget} do
      assert widget.alert.id == AlertWidgetInstance.alert_id(widget)
    end
  end
end
