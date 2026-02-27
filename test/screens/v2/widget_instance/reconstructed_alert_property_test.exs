defmodule Screens.V2.WidgetInstance.ReconstructedAlertPropertyTest do
  @moduledoc """
  This tests combinations of alert & stop ID for valid serialization.
  It does not check whether the serialization is accurate.
  There are a lot of stop ID + alert combos that are not valuable, and at this time
  we do not weed out unhelpful pairs. That could be a non-mandatory tech debt todo.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.Stops.Subway
  alias Screens.Util
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.PreFare

  import Screens.TestSupport.InformedEntityBuilder

  @stops_with_screens [
    {"place-asmnl", {"Ashmont", "Ashmont"}},
    {"place-bbsta", {"Back Bay", "Back Bay"}},
    {"place-chmnl", {"Charles/MGH", "Charles/MGH"}},
    {"place-forhl", {"Forest Hills", "Frst Hills"}},
    {"place-gover", {"Government Center", "Gov't Ctr"}},
    {"place-mvbcl", {"Maverick", "Maverick"}},
    {"place-portr", {"Porter", "Porter"}},
    {"place-tumnl", {"Tufts Medical Center", "Tufts Med"}},
    {"place-welln", {"Wellington", "Wellington"}},
    {"place-wondl", {"Wonderland", "Wonderland"}}
  ]

  @tag :capture_log
  property "reconstructed alert serialization" do
    alerts = [
      %Alert{
        active_period: [{~U[2022-09-07 13:02:00Z], ~U[2022-09-07 15:16:18Z]}],
        cause: :unknown,
        created_at: ~U[2022-09-07 13:02:33Z],
        description: "Affected stops:\r\nDavis\r\nPorter\r\nHarvard",
        effect: :suspension,
        header: "Red Line service suspended",
        id: "133885",
        informed_entities: [
          ie(stop_id: "70065", route: "Red", route_type: 1),
          ie(stop_id: "70066", route: "Red", route_type: 1),
          ie(stop_id: "70067", route: "Red", route_type: 1),
          ie(stop_id: "70068", route: "Red", route_type: 1),
          ie(stop_id: "70069", route: "Red", route_type: 1),
          ie(stop_id: "70070", route: "Red", route_type: 1),
          ie(stop_id: "place-cntsq", route: "Red", route_type: 1),
          ie(stop_id: "place-harsq", route: "Red", route_type: 1),
          ie(stop_id: "place-portr", route: "Red", route_type: 1)
        ],
        lifecycle: "NEW",
        severity: 7,
        timeframe: nil,
        updated_at: ~U[2022-09-07 13:16:14Z],
        url: nil
      },
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
          ie(stop_id: "70014", route: "Orange", route_type: 1),
          ie(stop_id: "70015", route: "Orange", route_type: 1),
          ie(stop_id: "70016", route: "Orange", route_type: 1),
          ie(stop_id: "70017", route: "Orange", route_type: 1),
          ie(stop_id: "70018", route: "Orange", route_type: 1),
          ie(stop_id: "70019", route: "Orange", route_type: 1),
          ie(stop_id: "70020", route: "Orange", route_type: 1),
          ie(stop_id: "70021", route: "Orange", route_type: 1),
          ie(stop_id: "70022", route: "Orange", route_type: 1),
          ie(stop_id: "70023", route: "Orange", route_type: 1),
          ie(stop_id: "70024", route: "Orange", route_type: 1),
          ie(stop_id: "70025", route: "Orange", route_type: 1),
          ie(stop_id: "70026", route: "Orange", route_type: 1),
          ie(stop_id: "70027", route: "Orange", route_type: 1),
          ie(stop_id: "place-bbsta", route: "Orange", route_type: 1),
          ie(stop_id: "place-chncl", route: "Orange", route_type: 1),
          ie(stop_id: "place-dwnxg", route: "Orange", route_type: 1),
          ie(stop_id: "place-haecl", route: "Orange", route_type: 1),
          ie(stop_id: "place-north", route: "Orange", route_type: 1),
          ie(stop_id: "place-state", route: "Orange", route_type: 1),
          ie(stop_id: "place-tumnl", route: "Orange", route_type: 1)
        ],
        lifecycle: "NEW",
        severity: 7,
        timeframe: nil,
        updated_at: ~U[2022-06-24 09:14:52Z],
        url: nil
      },
      %Alert{
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
          ie(stop_id: "place-north", route: "Green-D", route_type: 0),
          ie(stop_id: "70504", route: "Green-E", route_type: 0),
          ie(stop_id: "place-unsqu", route: "Green-E", route_type: 0),
          ie(stop_id: "place-spmnl", route: "Green-C", route_type: 0),
          ie(stop_id: "70204", route: "Green-C", route_type: 0),
          ie(stop_id: "70202", route: "Green-D", route_type: 0),
          ie(stop_id: "70501", route: "Green-D", route_type: 0),
          ie(stop_id: "70202", route: "Green-B", route_type: 0),
          ie(stop_id: "70207", route: "Green-D", route_type: 0),
          ie(stop_id: "place-unsqu", route: "Green-D", route_type: 0),
          ie(stop_id: "place-north", route: "Green-E", route_type: 0),
          ie(stop_id: "70208", route: "Green-D", route_type: 0),
          ie(stop_id: "70208", route: "Green-E", route_type: 0),
          ie(stop_id: "70206", route: "Green-B", route_type: 0),
          ie(stop_id: "place-lech", route: "Green-B", route_type: 0),
          ie(stop_id: "70205", route: "Green-B", route_type: 0),
          ie(stop_id: "place-north", route: "Green-B", route_type: 0),
          ie(stop_id: "70203", route: "Green-B", route_type: 0),
          ie(stop_id: "70201", route: "Green-C", route_type: 0),
          ie(stop_id: "place-gover", route: "Green-B", route_type: 0),
          ie(stop_id: "70206", route: "Green-C", route_type: 0),
          ie(stop_id: "place-unsqu", route: "Green-C", route_type: 0),
          ie(stop_id: "70504", route: "Green-C", route_type: 0),
          ie(stop_id: "70202", route: "Green-C", route_type: 0),
          ie(stop_id: "place-gover", route: "Green-C", route_type: 0),
          ie(stop_id: "70201", route: "Green-B", route_type: 0),
          ie(stop_id: "70504", route: "Green-B", route_type: 0),
          ie(stop_id: "place-lech", route: "Green-C", route_type: 0),
          ie(stop_id: "70501", route: "Green-B", route_type: 0),
          ie(stop_id: "70202", route: "Green-E", route_type: 0),
          ie(stop_id: "70208", route: "Green-B", route_type: 0),
          ie(stop_id: "place-gover", route: "Green-D", route_type: 0),
          ie(stop_id: "place-spmnl", route: "Green-D", route_type: 0),
          ie(stop_id: "70207", route: "Green-E", route_type: 0),
          ie(stop_id: "70204", route: "Green-B", route_type: 0),
          ie(stop_id: "70203", route: "Green-C", route_type: 0)
        ],
        lifecycle: "NEW",
        severity: 7,
        timeframe: nil,
        updated_at: ~U[2022-06-24 18:24:03Z],
        url: nil
      },
      %Screens.Alerts.Alert{
        active_period: [{~U[2022-08-20 01:00:00Z], ~U[2022-09-19 06:30:00Z]}],
        cause: :unknown,
        created_at: ~U[2022-08-03 17:32:41Z],
        description:
          "Alternative Travel Options for Riders:\r\n\r\nRiders commuting to downtown are encouraged to use the Commuter Rail. Zone 1A, 1, and 2 fares can be paid simply by showing a CharlieCard or CharlieTicket on ALL Commuter Rail lines. \r\n\r\nMost Needham and Providence Line Commuter Rail trains will stop at Forest Hills, Ruggles, Back Bay, and South Station.\r\nHaverhill Line Commuter Rail trains will stop at Oak Grove, Malden Center, and North Station. \r\n\r\nRiders can use other existing MBTA bus and subway services to complete their trips.\r\n\r\nShuttle bus service will operate in both directions, connecting Oak Grove and Forest Hills stations to downtown Boston. \r\n\r\nA Rider's Guide is available on mbta.com",
        effect: :suspension,
        header:
          "Orange Line service is suspended through Sun, Sep 18. This suspension will allow for upgrades and improvements of track and signal systems along the line.",
        id: "456090",
        informed_entities: [
          ie(stop_id: nil, route: "Orange", route_type: 1)
        ],
        lifecycle: "ONGOING",
        severity: 1,
        timeframe: "through September 18",
        updated_at: ~U[2022-08-22 16:38:57Z],
        url: "https://mbta.com/BBT2022"
      },
      %Screens.Alerts.Alert{
        active_period: [{~U[2022-08-22 08:30:00Z], ~U[2022-09-19 06:30:00Z]}],
        cause: :unknown,
        created_at: ~U[2022-08-08 15:11:48Z],
        description:
          "All shuttle buses will be accessible for passengers with disabilities. Haymarket station will not be serviced by shuttles due to the proximity to Government Center Garage demolition work. \r\n\r\nAffected stops:\r\nUnion Square\r\nLechmere\r\nScience Park/West End\r\nNorth Station\r\nHaymarket\r\nGovernment Center",
        effect: :shuttle,
        header:
          "Shuttle buses replace Green Line service between Union Square and Government Center through Sun, Sep 18. This is to allow for work on the Green Line Extension, the Lechmere Viaduct, and the Government Center Garage project.",
        id: "456774",
        informed_entities: [
          ie(stop_id: "place-haecl", route: "Green-E", route_type: 0),
          ie(stop_id: "place-north", route: "Green-D", route_type: 0),
          ie(stop_id: "place-lech", route: "Green-B", route_type: 0),
          ie(stop_id: "70204", route: "Green-B", route_type: 0),
          ie(stop_id: "70503", route: "Green-E", route_type: 0),
          ie(stop_id: "70202", route: "Green-B", route_type: 0),
          ie(stop_id: "place-gover", route: "Green-D", route_type: 0),
          ie(stop_id: "70206", route: "Green-D", route_type: 0),
          ie(stop_id: "70208", route: "Green-D", route_type: 0),
          ie(stop_id: "70206", route: "Green-B", route_type: 0),
          ie(stop_id: "70207", route: "Green-E", route_type: 0),
          ie(stop_id: "70203", route: "Green-E", route_type: 0),
          ie(stop_id: "place-north", route: "Green-E", route_type: 0),
          ie(stop_id: "70201", route: "Green-B", route_type: 0),
          ie(stop_id: "70502", route: "Green-C", route_type: 0),
          ie(stop_id: "place-spmnl", route: "Green-D", route_type: 0),
          ie(stop_id: "70501", route: "Green-C", route_type: 0),
          ie(stop_id: "70207", route: "Green-B", route_type: 0),
          ie(stop_id: "70204", route: "Green-D", route_type: 0),
          ie(stop_id: "70205", route: "Green-D", route_type: 0),
          ie(stop_id: "70201", route: "Green-D", route_type: 0),
          ie(stop_id: "70502", route: "Green-D", route_type: 0),
          ie(stop_id: "place-unsqu", route: "Green-E", route_type: 0),
          ie(stop_id: "place-haecl", route: "Green-B", route_type: 0),
          ie(stop_id: "70202", route: "Green-C", route_type: 0),
          ie(stop_id: "place-spmnl", route: "Green-E", route_type: 0),
          ie(stop_id: "70504", route: "Green-C", route_type: 0),
          ie(stop_id: "70503", route: "Green-D", route_type: 0),
          ie(stop_id: "place-gover", route: "Green-C", route_type: 0),
          ie(stop_id: "70205", route: "Green-B", route_type: 0),
          ie(stop_id: "70205", route: "Green-C", route_type: 0),
          ie(stop_id: "70502", route: "Green-E", route_type: 0),
          ie(stop_id: "70208", route: "Green-C", route_type: 0),
          ie(stop_id: "70207", route: "Green-C", route_type: 0),
          ie(stop_id: "place-gover", route: "Green-E", route_type: 0),
          ie(stop_id: "place-haecl", route: "Green-D", route_type: 0),
          ie(stop_id: "place-north", route: "Green-C", route_type: 0),
          ie(stop_id: "70201", route: "Green-E", route_type: 0),
          ie(stop_id: "place-unsqu", route: "Green-B", route_type: 0),
          ie(stop_id: "70502", route: "Green-B", route_type: 0),
          ie(stop_id: "70204", route: "Green-C", route_type: 0),
          ie(stop_id: "70201", route: "Green-C", route_type: 0),
          ie(stop_id: "70202", route: "Green-E", route_type: 0),
          ie(stop_id: "70504", route: "Green-E", route_type: 0),
          ie(stop_id: "place-lech", route: "Green-E", route_type: 0),
          ie(stop_id: "70503", route: "Green-B", route_type: 0),
          ie(stop_id: "70203", route: "Green-B", route_type: 0),
          ie(stop_id: "70203", route: "Green-D", route_type: 0),
          ie(stop_id: "place-haecl", route: "Green-C", route_type: 0),
          ie(stop_id: "70501", route: "Green-B", route_type: 0),
          ie(stop_id: "70206", route: "Green-C", route_type: 0),
          ie(stop_id: "70203", route: "Green-C", route_type: 0),
          ie(stop_id: "70208", route: "Green-B", route_type: 0),
          ie(stop_id: "70503", route: "Green-C", route_type: 0),
          ie(stop_id: "70208", route: "Green-E", route_type: 0),
          ie(stop_id: "place-lech", route: "Green-C", route_type: 0),
          ie(stop_id: "70204", route: "Green-E", route_type: 0),
          ie(stop_id: "70202", route: "Green-D", route_type: 0),
          ie(stop_id: "70501", route: "Green-E", route_type: 0),
          ie(stop_id: "70206", route: "Green-E", route_type: 0),
          ie(stop_id: "place-unsqu", route: "Green-C", route_type: 0),
          ie(stop_id: "70501", route: "Green-D", route_type: 0),
          ie(stop_id: "70205", route: "Green-E", route_type: 0),
          ie(stop_id: "place-unsqu", route: "Green-D", route_type: 0),
          ie(stop_id: "70504", route: "Green-B", route_type: 0),
          ie(stop_id: "place-gover", route: "Green-B", route_type: 0),
          ie(stop_id: "place-spmnl", route: "Green-B", route_type: 0),
          ie(stop_id: "70504", route: "Green-D", route_type: 0),
          ie(stop_id: "place-north", route: "Green-B", route_type: 0),
          ie(stop_id: "place-spmnl", route: "Green-C", route_type: 0),
          ie(stop_id: "70207", route: "Green-D", route_type: 0),
          ie(stop_id: "place-lech", route: "Green-D", route_type: 0)
        ],
        lifecycle: "ONGOING",
        severity: 7,
        timeframe: "through September 18",
        updated_at: ~U[2022-08-23 11:28:40Z],
        url: nil
      }
    ]

    # This runs the test 100 times
    check all(
            {stop_id, _abbrev} = stop <- StreamData.member_of(@stops_with_screens),
            random_pos_integer <- StreamData.positive_integer(),
            alert <- StreamData.member_of(alerts),
            max_runs: 1000
          ) do
      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(PreFare, %{reconstructed_alert_widget: %ScreensConfig.Alerts{stop_id: stop_id}})
        })

      # Randomly setting current time to Thu Jul 31 2025 23:59:59 GMT-0400 (Eastern Daylight Time)
      # We're not to worried about serialization differences based on time of alert
      # So as long as alerts don't have an end time, the alert should still be considered active on this date
      {:ok, now_datetime} = DateTime.from_unix(1_659_299_615)

      route_ids_at_stop =
        Subway.all_stop_sequences()
        |> Enum.filter(fn {_k, v} ->
          Enum.any?(v, fn sequence ->
            Enum.any?(sequence, fn stop_object ->
              stop_object === stop
            end)
          end)
        end)
        |> Enum.map(fn {route_id, _} -> route_id end)

      routes_at_stop =
        route_ids_at_stop
        |> Enum.map(fn route_id ->
          %{
            route_id: route_id,
            type: Util.route_type_from_id(route_id),
            # Don't need to test a lot of inactive routes, since that's rarer
            active?: rem(random_pos_integer, 4) > 0
          }
        end)

      tagged_station_sequences =
        Map.new(route_ids_at_stop, fn id -> {id, [Subway.route_stop_sequence(id)]} end)

      station_sequences = LocationContext.untag_stop_sequences(tagged_station_sequences)

      fetch_alerts_fn = fn _ -> {:ok, [alert]} end
      fetch_stop_name_fn = fn _ -> "Test" end

      fetch_location_context_fn = fn _, _, _ ->
        {:ok,
         %LocationContext{
           home_stop: stop_id,
           tagged_stop_sequences: tagged_station_sequences,
           upstream_stops: LocationContext.upstream_stop_id_set([stop_id], station_sequences),
           downstream_stops: LocationContext.downstream_stop_id_set([stop_id], station_sequences),
           routes: routes_at_stop,
           alert_route_types: LocationContext.route_type_filter(PreFare, [stop_id])
         }}
      end

      alert_widgets =
        CandidateGenerator.Widgets.ReconstructedAlert.reconstructed_alert_instances(
          config,
          now_datetime,
          fetch_alerts_fn,
          fetch_stop_name_fn,
          fetch_location_context_fn
        )

      Enum.each(alert_widgets, fn widget ->
        assert %{issue: _, location: _} = ReconstructedAlert.serialize(widget)
      end)
    end
  end
end
