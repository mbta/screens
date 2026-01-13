defmodule Screens.V2.WidgetInstance.DupAlertTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.V2.WidgetInstance.DupAlert
  alias ScreensConfig.{Departures, FreeTextLine, Screen}

  defp build_alert(fields) do
    struct!(%Alert{cause: :construction, effect: :suspension, severity: 5}, fields)
  end

  defp route_informed_entities(route_ids) do
    Enum.map(route_ids, &%{route_type: 1, route: &1, stop: nil, direction_id: nil})
  end

  defp stop_informed_entities(route_id, stop_ids) do
    Enum.map(stop_ids, &%{route_type: 1, route: route_id, stop: &1, direction_id: nil})
  end

  @tagged_stop_sequences %{
    "Blue" => [~w[place-b1 place-x place-b2 place-b3 place-b4]],
    "Red" => [~w[place-r1 place-r2 place-r3 place-x place-r4]]
  }

  @child_stops %{
    "Blue" => [
      %Screens.Stops.Stop{
        id: "child_plat_b0",
        platform_name: "Northbound",
        location_type: 0
      },
      %Screens.Stops.Stop{
        id: "child_plat_b1",
        platform_name: "Southbound",
        location_type: 0
      }
    ]
  }

  defp build_location_context(home_stop) do
    stop_sequences = LocationContext.untag_stop_sequences(@tagged_stop_sequences)

    %LocationContext{
      home_stop: home_stop,
      tagged_stop_sequences: @tagged_stop_sequences,
      upstream_stops: LocationContext.upstream_stop_id_set([home_stop], stop_sequences),
      downstream_stops: LocationContext.downstream_stop_id_set([home_stop], stop_sequences),
      routes: @tagged_stop_sequences |> Map.keys() |> Enum.map(&%{active?: true, route_id: &1}),
      alert_route_types: LocationContext.route_type_filter(Screen.Dup, [home_stop]),
      child_stops_at_station: @child_stops
    }
  end

  defp build_screen(primary_sections_count \\ 1, has_secondary_departures? \\ false) do
    struct(Screen,
      app_id: :dup_v2,
      app_params:
        struct(Screen.Dup,
          primary_departures: %Departures{
            sections: List.duplicate(struct(Departures.Section), primary_sections_count)
          },
          secondary_departures: %Departures{
            sections: if(has_secondary_departures?, do: [struct(Departures.Section)], else: [])
          }
        )
    )
  end

  defp all_rotations(screen, context, alert) do
    Enum.map(
      [:zero, :one, :two],
      &%DupAlert{
        screen: screen,
        location_context: context,
        alert: alert,
        rotation_index: &1,
        stop_name: "Test Stop"
      }
    )
  end

  describe "layout selection" do
    defp widget_types(screen, context, alert) do
      all_rotations(screen, context, alert) |> Enum.map(&DupAlert.widget_type/1)
    end

    test "all service eliminated at a single-line stop with only primary departures" do
      screen = build_screen()
      context = build_location_context("place-r2")

      alert =
        build_alert(
          informed_entities: stop_informed_entities("Red", ~w[place-r1 place-r2 place-r3])
        )

      assert widget_types(screen, context, alert) ==
               [:takeover_alert, :takeover_alert, :takeover_alert]
    end

    test "all service eliminated at a single-line stop with secondary departures" do
      screen = build_screen(1, true)
      context = build_location_context("place-r2")

      alert =
        build_alert(
          informed_entities: stop_informed_entities("Red", ~w[place-r1 place-r2 place-r3])
        )

      assert widget_types(screen, context, alert) ==
               [:takeover_alert, :takeover_alert, :banner_alert]
    end

    test "all service eliminated for both lines at a transfer stop" do
      screen = build_screen(2)
      context = build_location_context("place-x")

      alert =
        build_alert(
          informed_entities:
            stop_informed_entities("Red", ~w[place-r3 place-x place-r4]) ++
              stop_informed_entities("Blue", ~w[place-b1 place-x place-b2])
        )

      assert widget_types(screen, context, alert) ==
               [:takeover_alert, :takeover_alert, :takeover_alert]
    end

    test "all service eliminated for one line at a transfer stop" do
      screen = build_screen(2)
      context = build_location_context("place-x")

      alert =
        build_alert(
          informed_entities: stop_informed_entities("Red", ~w[place-r3 place-x place-r4])
        )

      assert widget_types(screen, context, alert) ==
               [:banner_alert, :takeover_alert, :banner_alert]
    end

    test "one direction of service eliminated" do
      screen = build_screen()
      context = build_location_context("place-r1")

      alert =
        build_alert(
          informed_entities: stop_informed_entities("Red", ~w[place-r1 place-r2 place-r3])
        )

      assert widget_types(screen, context, alert) ==
               [:banner_alert, :takeover_alert, :banner_alert]
    end

    test "alert effect does not eliminate service" do
      screen = build_screen()
      context = build_location_context("place-r2")
      alert = build_alert(effect: :delay, informed_entities: route_informed_entities(~w[Red]))

      assert widget_types(screen, context, alert) ==
               [:banner_alert, :banner_alert, :banner_alert]
    end
  end

  describe "layout serialization" do
    defp serialized(screen, context, alert) do
      all_rotations(screen, context, alert) |> Enum.map(&DupAlert.serialize/1)
    end

    defmacrop bold(text) do
      quote do
        %{format: :bold, text: unquote(text)}
      end
    end

    defmacrop pill(route) do
      quote do
        %{route: unquote(route)}
      end
    end

    test "single-line delays" do
      screen = build_screen()
      context = build_location_context("place-r2")
      alert = build_alert(effect: :delay, informed_entities: route_informed_entities(~w[Red]))

      banner = %{
        color: :red,
        text: %FreeTextLine{icon: :delay, text: [bold("Red Line"), "delays"]}
      }

      assert serialized(screen, context, alert) == [banner, banner, banner]
    end

    test "multi-line delays" do
      screen = build_screen(2, false)
      context = build_location_context("place-x")

      alert =
        build_alert(effect: :delay, informed_entities: route_informed_entities(~w[Red Blue]))

      # BUG: shows a white delay icon on a yellow background, need an inverse delay icon
      banner = %{color: :yellow, text: %FreeTextLine{icon: :delay, text: ["Train delays"]}}

      assert serialized(screen, context, alert) == [banner, banner, banner]
    end

    test "inside non-severe single-tracking" do
      screen = build_screen()
      context = build_location_context("place-r2")

      alert =
        build_alert(
          cause: :single_tracking,
          effect: :delay,
          severity: 4,
          informed_entities: route_informed_entities(~w[Red])
        )

      banner = %{
        color: :red,
        text: %FreeTextLine{icon: :delay, text: [bold("Red Line"), "delays"]}
      }

      assert serialized(screen, context, alert) == [banner, banner, banner]
    end

    test "inside or on the boundary of severe single-tracking" do
      screen = build_screen()
      inside_context = build_location_context("place-r2")
      outside_context = build_location_context("place-r3")

      alert =
        build_alert(
          cause: :single_tracking,
          effect: :delay,
          severity: 5,
          informed_entities: stop_informed_entities("Red", ~w[place-r1 place-r2 place-r3])
        )

      banner = %{
        color: :red,
        text: %FreeTextLine{icon: :delay, text: [bold("Red Line"), "delays"]}
      }

      takeover = %{
        header: %{color: :red, text: "Test Stop"},
        text: %FreeTextLine{
          icon: :delay,
          text: [
            pill(:red),
            bold("delays"),
            bold("up to 20 minutes"),
            "due to",
            "single tracking"
          ]
        },
        remedy: %FreeTextLine{icon: nil, text: []}
      }

      assert serialized(screen, inside_context, alert) == [banner, takeover, banner]
      assert serialized(screen, outside_context, alert) == [banner, takeover, banner]
    end

    test "single-line inside shuttle" do
      screen = build_screen()
      context = build_location_context("place-r2")

      alert =
        build_alert(
          effect: :shuttle,
          informed_entities: stop_informed_entities("Red", ~w[place-r1 place-r2 place-r3])
        )

      takeover = %{
        header: %{color: :red, text: "Test Stop"},
        text: %FreeTextLine{
          icon: :warning,
          text: [bold("No"), pill(:red), bold("trains"), "due to", "construction"]
        },
        remedy: %FreeTextLine{icon: :shuttle, text: [bold("Use shuttle bus")]}
      }

      assert serialized(screen, context, alert) == [takeover, takeover, takeover]
    end

    test "single-line inside non-shuttle" do
      screen = build_screen()
      context = build_location_context("place-r2")

      alert =
        build_alert(
          effect: :station_closure,
          informed_entities: stop_informed_entities("Red", ~w[place-r2])
        )

      takeover = %{
        header: %{color: :red, text: "Test Stop"},
        text: %FreeTextLine{
          icon: :warning,
          text: [bold("No"), pill(:red), bold("trains"), "due to", "construction"]
        },
        remedy: %FreeTextLine{icon: nil, text: ["Seek alternate route"]}
      }

      assert serialized(screen, context, alert) == [takeover, takeover, takeover]
    end

    test "Single platform closure" do
      screen = build_screen()
      context = build_location_context("place-x")

      alert =
        build_alert(
          effect: :station_closure,
          cause: :unknown,
          severity: 7,
          informed_entities: stop_informed_entities("Blue", ~w[place-x child_plat_b0])
        )

      banner = %{
        color: :blue,
        text: %FreeTextLine{icon: :warning, text: ["No", bold("Northbound")]}
      }

      takeover = %{
        header: %{color: :blue, text: "Test Stop"},
        text: %FreeTextLine{
          icon: :warning,
          text: [bold("Northbound platform closed")]
        },
        remedy: %FreeTextLine{icon: nil, text: ["Seek alternate route"]}
      }

      assert serialized(screen, context, alert) == [banner, takeover, banner]
    end

    test "boundary" do
      screen = build_screen()
      context = build_location_context("place-r1")

      alert =
        build_alert(
          informed_entities: stop_informed_entities("Red", ~w[place-r1 place-r2 place-r3])
        )

      banner = %{
        color: :red,
        text: %FreeTextLine{icon: :warning, text: ["No", bold("Test R1"), "trains"]}
      }

      takeover = %{
        header: %{color: :red, text: "Test Stop"},
        text: %FreeTextLine{
          icon: :warning,
          text: [bold("No"), pill(:red), bold("trains"), bold("to Test R1")]
        },
        remedy: %FreeTextLine{icon: nil, text: ["Seek alternate route"]}
      }

      assert serialized(screen, context, alert) == [banner, takeover, banner]
    end

    test "multi-line inside single-line disruption" do
      screen = build_screen(2)
      context = build_location_context("place-x")

      alert =
        build_alert(
          informed_entities: stop_informed_entities("Red", ~w[place-r3 place-x place-r4])
        )

      banner = %{
        color: :red,
        text: %FreeTextLine{icon: :warning, text: ["No", bold("Red Line"), "trains"]}
      }

      takeover = %{
        header: %{color: :red, text: "Test Stop"},
        text: %FreeTextLine{
          icon: :warning,
          text: [bold("No"), pill(:red), bold("trains"), "due to", "construction"]
        },
        remedy: %FreeTextLine{icon: nil, text: ["Seek alternate route"]}
      }

      assert serialized(screen, context, alert) == [banner, takeover, banner]
    end

    test "multi-line disruption" do
      screen = build_screen(2)
      context = build_location_context("place-x")

      alert =
        build_alert(
          informed_entities:
            stop_informed_entities("Red", ~w[place-r3 place-x place-r4]) ++
              stop_informed_entities("Blue", ~w[place-b1 place-x place-b2])
        )

      takeover = %{
        header: %{color: :yellow, text: "Test Stop"},
        text: %FreeTextLine{icon: :warning, text: ["No", pill(:blue), "or", pill(:red), "trains"]},
        remedy: %FreeTextLine{icon: nil, text: ["Seek alternate route"]}
      }

      assert serialized(screen, context, alert) == [takeover, takeover, takeover]
    end
  end
end
