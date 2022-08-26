defmodule Screens.V2.CandidateGenerator.Widgets.CRDeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Config.Screen
  # alias Screens.Config.V2.Departures.Filter.RouteDirection
  # alias Screens.Config.V2.Departures.{Filter, Section}
  alias Screens.Config.V2.PreFare
  alias Screens.Config.V2.CRDepartures, as: CRDeparturesConfig
  # alias Screens.V2.CandidateGenerator.Widgets.Departures
  # alias Screens.V2.Departure
  # alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  # alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}
  # alias Screens.Predictions.Prediction
  # alias Screens.Routes.Route
  # alias Screens.Trips.Trip

  describe "departures_instances/1" do
    setup do
      config = %Screen{
        app_params: %PreFare{
          cr_departures: %CRDeparturesConfig{
            station: "place-forhl",
            destination: "place-bbsta",
            direction_to_destination: 1,
            wayfinding_arrows: "right-down",
            priority: [1],
            travel_time_to_destination: "9-12m",
            show_via_headsigns_message: false
          },
          header: nil,
          reconstructed_alert_widget: nil,
          elevator_status: nil,
          full_line_map: nil,
          content_summary: nil
        },
        vendor: nil,
        device_id: nil,
        name: nil,
        app_id: nil
      }

      %{config: config}
    end

    # test "returns DeparturesWidget when all section requests succeed and receive departure data",
    #      %{config: config} do
    #   fetch_departures_fn = fn _, _ -> ["departure 1", "departure 2", "departure 3"] end

    #   expected_departures_instances = [
    #     %CRDeparturesWidget{
    #       config: config.app_params.cr_departures,
    #       departures_data: ["departure 1", "departure 2", "departure 3"]
    #     }
    #   ]

    #   actual_departures_instances =
    #     CRDeparturesWidget.departures_instances(config, fetch_departures_fn)

    #   assert expected_departures_instances == actual_departures_instances
    # end

    # test "returns DeparturesWidget when all sections requests succeed but receive no departure data",
    #      %{config: config} do
    #   fetch_departures_fn = fn _, _ -> [] end

    #   expected_departures_instances = [
    #     %CRDeparturesWidget{
    #       config: config.app_params.cr_departures,
    #       departures_data: []
    #     }
    #   ]

    #   actual_departures_instances =
    #     Departures.departures_instances(config, fetch_departures_fn)

    #   assert expected_departures_instances == actual_departures_instances
    # end

    # test "returns DeparturesNoData if any section request fails", %{config: config} do
    #   fetch_section_departures_fn = fn
    #     %Section{query: "query A"} -> {:ok, []}
    #     %Section{query: "query B"} -> :error
    #   end

    #   expected_departures_instances = [
    #     %DeparturesNoData{screen: config, show_alternatives?: true}
    #   ]

    #   actual_departures_instances =
    #     Departures.departures_instances(config, fetch_section_departures_fn)

    #   assert expected_departures_instances == actual_departures_instances
    # end

    # test "returns OvernightDepartures if sections_data contains overnight atom", %{config: config} do
    #   fetch_section_departures_fn = fn
    #     %Section{query: "query A"} -> {:ok, []}
    #     %Section{query: "query B"} -> {:ok, []}
    #   end

    #   post_processing_fn = fn _sections, _config ->
    #     [:overnight]
    #   end

    #   expected_departures_instances = [
    #     %OvernightDepartures{}
    #   ]

    #   actual_departures_instances =
    #     Departures.departures_instances(config, fetch_section_departures_fn, post_processing_fn)

    #   assert expected_departures_instances == actual_departures_instances
    # end
  end
end
