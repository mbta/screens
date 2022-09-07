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
  alias Screens.Config.Screen
  alias Screens.Config.V2.{PreFare}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  # TBD: should have more alerts that match troublesome alerts we've seen before
  @alerts [
    %Alert{
      active_period: [{~U[2022-09-07 13:02:00Z], ~U[2022-09-07 15:16:18Z]}],
      cause: :unknown,
      created_at: ~U[2022-09-07 13:02:33Z],
      description: "Affected stops:\r\nDavis\r\nPorter\r\nHarvard",
      effect: :suspension,
      header: "Red Line service suspended",
      id: "133885",
      informed_entities: [
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "70065"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "70066"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "70067"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "70068"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "70069"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "70070"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "place-cntsq"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Red",
          route_type: 1,
          stop: "place-portr"
        }
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
        %{
          direction_id: nil,
          facility: nil,
          route: "Orange",
          route_type: 1,
          stop: nil
        }
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
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
          route_type: 0,
          stop: "place-haecl"
        },
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
          route: "Green-B",
          route_type: 0,
          stop: "place-lech"
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
          route: "Green-E",
          route_type: 0,
          stop: "70503"
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
          stop: "place-gover"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-D",
          route_type: 0,
          stop: "70206"
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
          route: "Green-B",
          route_type: 0,
          stop: "70206"
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
          route: "Green-E",
          route_type: 0,
          stop: "70203"
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
          route: "Green-B",
          route_type: 0,
          stop: "70201"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-C",
          route_type: 0,
          stop: "70502"
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
          route: "Green-C",
          route_type: 0,
          stop: "70501"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-B",
          route_type: 0,
          stop: "70207"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-D",
          route_type: 0,
          stop: "70204"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-D",
          route_type: 0,
          stop: "70205"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-D",
          route_type: 0,
          stop: "70201"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-D",
          route_type: 0,
          stop: "70502"
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
          route: "Green-B",
          route_type: 0,
          stop: "place-haecl"
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
          route: "Green-E",
          route_type: 0,
          stop: "place-spmnl"
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
          route: "Green-D",
          route_type: 0,
          stop: "70503"
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
          stop: "70205"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-C",
          route_type: 0,
          stop: "70205"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
          route_type: 0,
          stop: "70502"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-C",
          route_type: 0,
          stop: "70208"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-C",
          route_type: 0,
          stop: "70207"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
          route_type: 0,
          stop: "place-gover"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-D",
          route_type: 0,
          stop: "place-haecl"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-C",
          route_type: 0,
          stop: "place-north"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
          route_type: 0,
          stop: "70201"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-B",
          route_type: 0,
          stop: "place-unsqu"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-B",
          route_type: 0,
          stop: "70502"
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
          route: "Green-C",
          route_type: 0,
          stop: "70201"
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
          route: "Green-E",
          route_type: 0,
          stop: "70504"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
          route_type: 0,
          stop: "place-lech"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-B",
          route_type: 0,
          stop: "70503"
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
          route: "Green-D",
          route_type: 0,
          stop: "70203"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-C",
          route_type: 0,
          stop: "place-haecl"
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
          route: "Green-C",
          route_type: 0,
          stop: "70206"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-C",
          route_type: 0,
          stop: "70203"
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
          route: "Green-C",
          route_type: 0,
          stop: "70503"
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
          route: "Green-C",
          route_type: 0,
          stop: "place-lech"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
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
          route: "Green-E",
          route_type: 0,
          stop: "70501"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
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
          route: "Green-D",
          route_type: 0,
          stop: "70501"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-E",
          route_type: 0,
          stop: "70205"
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
          route: "Green-B",
          route_type: 0,
          stop: "70504"
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
          route: "Green-B",
          route_type: 0,
          stop: "place-spmnl"
        },
        %{
          direction_id: nil,
          facility: nil,
          route: "Green-D",
          route_type: 0,
          stop: "70504"
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
          route: "Green-C",
          route_type: 0,
          stop: "place-spmnl"
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
          stop: "place-lech"
        }
      ],
      lifecycle: "ONGOING",
      severity: 7,
      timeframe: "through September 18",
      updated_at: ~U[2022-08-23 11:28:40Z],
      url: nil
    }
  ]

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

  property "reconstructed alert serialization" do
    # This runs the test 100 times
    check all(
            {stop_id, _abbrev} = stop <- StreamData.member_of(@stops_with_screens),
            random_pos_integer <- StreamData.positive_integer(),
            alert <- StreamData.member_of(@alerts),
            max_runs: 1000
          ) do
      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(PreFare, %{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}})
        })

      # Randomly setting current time to Thu Jul 31 2025 23:59:59 GMT-0400 (Eastern Daylight Time)
      # We're not to worried about serialization differences based on time of alert
      # So as long as alerts don't have an end time, the alert should still be considered active on this date
      {:ok, now_datetime} = DateTime.from_unix(1_659_299_615)

      route_ids_at_stop =
        Stop.get_all_routes_stop_sequence()
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

      station_sequences =
        Enum.map(route_ids_at_stop, fn id -> Stop.get_route_stop_sequence(id) end)

      fetch_routes_by_stop_fn = fn _, _, _ -> {:ok, routes_at_stop} end

      fetch_parent_station_sequences_through_stop_fn = fn _, _ ->
        {:ok, station_sequences}
      end

      fetch_alerts_fn = fn _ -> {:ok, [alert]} end
      fetch_stop_name_fn = fn _ -> "Test" end

      alert_widgets =
        CandidateGenerator.Widgets.ReconstructedAlert.reconstructed_alert_instances(
          config,
          now_datetime,
          fetch_routes_by_stop_fn,
          fetch_parent_station_sequences_through_stop_fn,
          fetch_alerts_fn,
          fetch_stop_name_fn
        )

      Enum.each(alert_widgets, fn widget ->
        assert %{issue: _, location: _, routes: _} = ReconstructedAlert.serialize(widget)
      end)
    end
  end
end
