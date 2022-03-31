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
          | app_params: struct(app_config_module, %{header: %CurrentStopId{stop_id: stop_id}})
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

  defp ie(opts \\ []) do
    %{stop: opts[:stop], route: opts[:route], route_type: opts[:route_type]}
  end

  # Setting up screen location context
  defp setup_home_stop(%{widget: widget}) do
    home_stop = "place-pktrm"

    %{widget: put_home_stop(widget, PreFare, home_stop)}
  end

  defp setup_stop_sequences(%{widget: widget}) do
    stop_sequences = [
      ["place-knncl", "place-chmnl", "place-pktrm", "place-dwnxg", "place-sstat"],
      ["place-gover", "place-pktrm", "place-boyls", "place-armnl"]
    ]

    %{widget: put_stop_sequences(widget, stop_sequences)}
  end

  defp setup_routes(%{widget: widget}) do
    routes = [
      %{
        route_id: "a",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      },
      %{
        route_id: "b",
        active?: false,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      },
      %{
        route_id: "c",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :light_rail
      }
    ]

    %{widget: put_routes_at_stop(widget, routes)}
  end

  # routes = [
  #   %{route_id: "a", active?: true, direction_destinations: nil,
  #   long_name: nil,
  #   short_name: nil,
  #   type: :subway},
  #   %{route_id: "b", active?: false, direction_destinations: nil,
  #   long_name: nil,
  #   short_name: nil,
  #   type: :subway},
  #   %{route_id: "c", active?: true, direction_destinations: nil,
  #   long_name: nil,
  #   short_name: nil,
  #   type: :subway}
  # ]

  defp setup_screen_config(%{widget: widget}) do
    %{widget: put_app_id(widget, :pre_fare_v2)}
  end

  defp setup_now(%{widget: widget}) do
    %{widget: put_now(widget, ~U[2021-01-01T00:00:00Z])}
  end

  # Setting up alert related stuff
  defp setup_informed_entities(%{widget: widget}) do
    %{widget: put_informed_entities(widget, [ie(stop: "place-pktrm")])}
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
    :setup_now
  ]

  # Pass this to `setup` to set up a stop_closure alert that is currently active (just started) and affects the home stop.
  @valid_alert_setup_group @alert_widget_context_setup_group ++
                             [
                               :setup_informed_entities,
                               :setup_active_period,
                               :setup_effect
                             ]

  describe "priority/1 and slot_names/1" do
    setup @valid_alert_setup_group

    test "returns takeover for a closure alert at this station", %{widget: widget} do
      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
    end

    test "returns takeover for a suspension that affects all station trips", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(route: "a"), ie(route: "c")])
      assert [1] == WidgetInstance.priority(widget)
      assert [:full_body] == WidgetInstance.slot_names(widget)
    end

    test "returns flex zone alert for a suspension that affects some station trips", %{
      widget: widget
    } do
      widget = put_informed_entities(widget, [ie(route: "a"), ie(route: "b")])
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
    end

    test "returns flex zone alert for a downstream alert", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(stop: "place-gover")])
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
    end

    test "returns flex zone alert for a boundary alert", %{widget: widget} do
      widget = put_informed_entities(widget, [ie(stop: "place-gover"), ie(stop: "place-pktrm")])
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
    end

    test "returns flex zone alert for a severe delay", %{widget: widget} do
      widget = put_effect(widget, :severe_delay)
      assert [3] == WidgetInstance.priority(widget)
      assert [:large] == WidgetInstance.slot_names(widget)
    end
  end

  # describe "serialize_route/2" do
  #   test "returns normal service when there are no alerts" do
  #   end

  #   test "handles multiple alerts" do
  #   end

  #   test "handles shuttle alert" do
  #   end

  #   test "handles whole line shuttle alert" do
  #   end

  #   test "handles suspension alert" do
  #   end

  #   test "handles whole line suspension alert" do
  #   end

  #   test "handles delay alert" do
  #   end

  #   test "handles directional delay alert" do
  #   end

  #   test "handles single station closure" do
  #   end

  #   test "handles 2 station closure" do
  #   end

  #   test "handles 3 station closure" do
  # end

  # describe "serialize_green_line/1" do
  #   test "handles single branch shuttle" do
  #   end

  #   test "handles concurrent branch shuttles" do
  #   end

  #   test "handles concurrent branch shuttle and suspension" do
  #   end

  #   test "handles trunk alert" do
  #   end

  #   test "handles normal service" do
  #   end

  #   test "handles alert affecting all branches" do
  #   end
  # end

  describe "widget_type/1" do
    test "returns subway status", %{widget: widget} do
      assert :reconstructed_alert == WidgetInstance.widget_type(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string" do
      instance = %ReconstructedAlert{}
      assert %{} == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]" do
      instance = %ReconstructedAlert{}
      assert [0] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false" do
      instance = %ReconstructedAlert{}
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns ReconstructedAlertView" do
      instance = %ReconstructedAlert{}
      assert ScreensWeb.V2.Audio.ReconstructedAlertView == WidgetInstance.audio_view(instance)
    end
  end
end
