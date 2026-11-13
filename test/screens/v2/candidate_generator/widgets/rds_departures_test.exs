defmodule Screens.V2.CandidateGenerator.Widgets.RdsDeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Lines.Line
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.Widgets.RdsDepartures
  alias Screens.V2.RDS
  alias Screens.V2.RDS.ImpactedByAlert
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.Departures.NormalSection.AlertRow
  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.{Header, Layout, Params, Section}
  alias ScreensConfig.Screen

  @alert %Alert{id: "alert-1"}

  defp build_screen(app_id) do
    %Screen{
      app_id: app_id,
      app_params: nil,
      vendor: :test,
      device_id: "TEST",
      name: "TEST"
    }
  end

  defp build_section do
    %Section{
      header: %Header{subtitle: "Subtitle", arrow: :ne},
      layout: %Layout{},
      grouping_type: :time,
      params: %Params{mode: :rl}
    }
  end

  defp build_alert_item(route_id, displayed_headsign, direction_id \\ 0, mode \\ :rl) do
    %ImpactedByAlert{
      alert: @alert,
      direction_id: direction_id,
      displayed_headsign: displayed_headsign,
      location: :inside,
      routes: [%Route{id: route_id}],
      destinations: [{%Stop{id: "s1"}, %Line{id: "l1"}, displayed_headsign}],
      mode: mode
    }
  end

  defp build_countdown_item(_route_id, headsign) do
    destination = {%Stop{id: "s1"}, %Line{id: "l1"}, headsign}

    # Create a minimal departure with required fields
    departure = %Screens.V2.Departure{
      prediction: %Screens.Predictions.Prediction{
        route: %Route{id: "r1"},
        trip: %Screens.Trips.Trip{direction_id: 0},
        arrival_time: DateTime.utc_now()
      }
    }

    %RDS.Countdowns{
      destinations: [destination],
      departures: [departure]
    }
  end

  describe "create_departure_sections/4 for screens without departure alerts" do
    test "filters out alert items when there are other items in a section" do
      dup_screen = build_screen(:dup_v2)
      bus_shelter_screen = build_screen(:bus_shelter_v2)
      section = build_section()

      alert_item = build_alert_item("r1", "Downtown")
      countdown_item = build_countdown_item("r1", "Downtown")

      rds_data = [{:ok, [alert_item, countdown_item]}]
      departures_config = %Departures{sections: [section]}

      # DUP screen test
      dup_result =
        RdsDepartures.create_departure_sections(rds_data, departures_config, dup_screen)

      assert length(dup_result) == 1
      {_section, dup_widgets} = List.first(dup_result)

      # Alerts should be filtered out when there are other items
      assert %NormalSection{} = dup_widgets
      assert !Enum.any?(dup_widgets.rows, &match?(%AlertRow{}, &1))

      # Bus Shelter screen test
      bus_shelter_result =
        RdsDepartures.create_departure_sections(rds_data, departures_config, bus_shelter_screen)

      assert length(bus_shelter_result) == 1
      {_section, bus_widgets} = List.first(bus_shelter_result)

      # Alerts should be filtered out when there are other items
      assert %NormalSection{} = bus_widgets
      assert !Enum.any?(bus_widgets.rows, &match?(%AlertRow{}, &1))
    end

    test "returns empty section when all items are alerts" do
      screen = build_screen(:dup_v2)
      section = build_section()

      alert_item1 = build_alert_item("r1", "Downtown")
      alert_item2 = build_alert_item("r2", "Uptown")

      rds_data = [{:ok, [alert_item1, alert_item2]}]
      departures_config = %Departures{sections: [section]}

      result = RdsDepartures.create_departure_sections(rds_data, departures_config, screen)

      assert length(result) == 1
      {_section, widget_section} = List.first(result)

      # On screens that don't support Departure alerts, when all items are alerts, no rows should be shown
      assert %NormalSection{} = widget_section
      assert widget_section.rows == []
    end

    test "handles multiple sections with mixed content" do
      screen = build_screen(:dup_v2)
      section = build_section()

      alert_item = build_alert_item("r1", "Downtown")
      countdown_item = build_countdown_item("r1", "Downtown")
      alert_item2 = build_alert_item("r2", "Uptown")

      rds_data = [
        {:ok, [alert_item, countdown_item]},
        {:ok, [alert_item2]}
      ]

      departures_config = %Departures{sections: [section, section]}

      result = RdsDepartures.create_departure_sections(rds_data, departures_config, screen)

      assert length(result) == 2

      # First section should have alert filtered out, showing only departures
      {_section1, widget_section1} = Enum.at(result, 0)
      assert %NormalSection{} = widget_section1
      assert !Enum.any?(widget_section1.rows, &match?(%AlertRow{}, &1))

      # Second section should have empty rows (all alerts)
      {_section2, widget_section2} = Enum.at(result, 1)
      assert %NormalSection{} = widget_section2
      assert widget_section2.rows == []
    end
  end

  describe "create_departure_sections/4 for screens with departure alerts" do
    test "never filters alerts on screens with departure alerts" do
      screen = build_screen(:pre_fare_v2)
      section = build_section()

      alert_item = build_alert_item("r1", "Downtown")
      countdown_item = build_countdown_item("r1", "Downtown")

      rds_data = [{:ok, [alert_item, countdown_item]}]
      departures_config = %Departures{sections: [section]}

      result = RdsDepartures.create_departure_sections(rds_data, departures_config, screen)

      assert length(result) == 1
      {_section, widget_section} = List.first(result)

      assert Enum.any?(widget_section.rows, &match?(%AlertRow{}, &1))
      assert Enum.any?(widget_section.rows, &match?(%Screens.V2.Departure{}, &1))
    end

    test "combines alert only sections that are the same mode" do
      screen = build_screen(:pre_fare_v2)
      section = build_section()
      section_two = build_section()

      alert_item = build_alert_item("r1", "Downtown")
      alert_item_two = build_alert_item("r1", "Uptown")

      rds_data = [{:ok, [alert_item]}, {:ok, [alert_item_two]}]
      departures_config = %Departures{sections: [section, section_two]}

      result = RdsDepartures.create_departure_sections(rds_data, departures_config, screen)

      assert length(result) == 1
      {_section, widget_section} = List.first(result)

      assert Enum.all?(widget_section.rows, &match?(%AlertRow{displayed_headsign: nil}, &1))
      assert match?(%Header{arrow: "", subtitle: nil}, widget_section.header)
    end

    test "combines alert only sections that are different modes" do
      screen = build_screen(:pre_fare_v2)
      section = build_section()
      section_two = build_section()

      alert_item = build_alert_item("r1", "Downtown", 0, :gl)
      alert_item_two = build_alert_item("r1", "Uptown", 0, :rl)

      rds_data = [{:ok, [alert_item]}, {:ok, [alert_item_two]}]
      departures_config = %Departures{sections: [section, section_two]}

      result = RdsDepartures.create_departure_sections(rds_data, departures_config, screen)

      assert length(result) == 1
      {_section, widget_section} = List.first(result)

      assert Enum.all?(widget_section.rows, &match?(%AlertRow{displayed_headsign: nil}, &1))
      assert match?(%Header{arrow: "", subtitle: nil}, widget_section.header)
    end
  end
end
