defmodule Screens.V2.WidgetInstance.DupSpecialCaseAlertTest do
  use ExUnit.Case, async: true
  
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Alerts, Departures, Dup, FreeTextLine} 
  alias Screens.V2.CandidateGenerator.Dup.Alerts, as: DupAlerts
  alias Screens.V2.WidgetInstance.DupSpecialCaseAlert

  describe "dup alert_instances/6 > serialize/1" do
    setup do
      config_kenmore =
        struct(Screen, %{
          app_params: %Dup{
            primary_departures: struct(Departures),
            secondary_departures: struct(Departures),
            alerts: %Alerts{stop_id: "place-kencl"},
            header: %{stop_id: "place-kencl"}
          },
          app_id: :dup_v2
        })
      config_wtc =
        struct(Screen, %{
          app_params: %Dup{
            primary_departures: struct(Departures),
            secondary_departures: struct(Departures),
            alerts: %Alerts{stop_id: "place-wtcst"},
            header: %{stop_id: "place-wtcst"}
          },
          app_id: :dup_v2
        })

      now = ~U[2023-04-14T12:00:00Z]

      kenmore_routes = [
        %{
          active?: true,
          direction_destinations: ["Boston College", "Government Center"],
          long_name: "Green Line B",
          route_id: "Green-B",
          short_name: "B",
          type: :light_rail
        },
        %{
          active?: true,
          direction_destinations: ["Cleveland Circle", "Government Center"],
          long_name: "Green Line C",
          route_id: "Green-C",
          short_name: "C",
          type: :light_rail
        },
        %{
          active?: true,
          direction_destinations: ["Riverside", "Union Square"],
          long_name: "Green Line D",
          route_id: "Green-D",
          short_name: "D",
          type: :light_rail
        }
      ]

      wtc_routes = [
        %{
          active?: true,
          direction_destinations: ["Logan Airport Terminals", "South Station"],
          long_name: "Logan Airport Terminals - South Station",
          route_id: "741",
          short_name: "SL1",
          type: :bus
        },
        %{
          active?: true,
          direction_destinations: ["Drydock Avenue", "South Station"],
          long_name: "Drydock Avenue - South Station",
          route_id: "742",
          short_name: "SL2",
          type: :bus
        },
        %{
          active?: true,
          direction_destinations: ["Chelsea Station", "South Station"],
          long_name: "Chelsea Station - South Station",
          route_id: "743",
          short_name: "SL3",
          type: :bus
        }
      ]

      kenmore_alerts = [
        # WB B shuttle alert at Kenmore
        %Screens.Alerts.Alert{
          active_period: [{~U[2023-04-14 10:29:51Z], ~U[2023-04-14 21:30:05Z]}],
          cause: :unknown,
          created_at: ~U[2023-04-14 10:29:52Z],
          description: "Affected stops:\r\nKenmore\r\nBlandford Street\r\nBoston University East\r\nBoston University Central",
          effect: :shuttle,
          header: "Shuttle buses replacing Green Line B branch service",
          id: "137269",
          informed_entities: [
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70144"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70145"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70146"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70147"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70148"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70149"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "71150"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "71151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-bland"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-bucen"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-buest"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-kencl"
            }
          ],
          lifecycle: "NEW",
          severity: 7,
          timeframe: nil,
          updated_at: ~U[2023-04-14 19:29:52Z],
          url: nil
        },
        # WB C shuttle alert at Kenmore
        %Screens.Alerts.Alert{
          active_period: [{~U[2023-04-14 10:32:16Z], ~U[2023-04-14 21:32:22Z]}],
          cause: :unknown,
          created_at: ~U[2023-04-14 10:32:17Z],
          description: "Affected stops:\r\nKenmore\r\nSaint Mary's Street\r\nHawes Street",
          effect: :shuttle,
          header: "Shuttle buses replacing Green Line C branch service",
          id: "137270",
          informed_entities: [
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70150"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70211"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70212"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70213"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70214"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-hwsst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-kencl"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-smary"
            }
          ],
          lifecycle: "NEW",
          severity: 7,
          timeframe: nil,
          updated_at: ~U[2023-04-14 19:32:17Z],
          url: nil
        },
        # WB D shuttle alert at Kenmore
        %Screens.Alerts.Alert{
          active_period: [{~U[2023-04-14 10:52:44Z], ~U[2023-04-14 21:52:49Z]}],
          cause: :unknown,
          created_at: ~U[2023-04-14 10:52:45Z],
          description: "Affected stops:\r\nKenmore\r\nFenway",
          effect: :shuttle,
          header: "Shuttle buses replacing Green Line D branch service",
          id: "137272",
          informed_entities: [
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70150"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70186"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70187"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-fenwy"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-kencl"
            }
          ],
          lifecycle: "NEW",
          severity: 7,
          timeframe: nil,
          updated_at: ~U[2023-04-14 19:52:45Z],
          url: nil
        },
        # WB B / C / D shuttle alert at Kenmore
        %Screens.Alerts.Alert{
          active_period: [{~U[2023-04-14 10:53:53Z], ~U[2023-04-14 21:53:59Z]}],
          cause: :unknown,
          created_at: ~U[2023-04-14 10:53:54Z],
          description: "Affected stops:\r\nKenmore\r\nBlandford Street\r\nSaint Mary's Street\r\nFenway",
          effect: :shuttle,
          header: "Shuttle buses replacing Green Line service",
          id: "137273",
          informed_entities: [
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70187"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70149"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "71151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70148"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70149"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "71150"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-smary"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "place-fenwy"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-bland"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-kencl"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70187"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-smary"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "place-bland"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70148"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70186"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70150"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "71151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "71150"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-bland"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70148"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "place-smary"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "place-fenwy"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "71151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70212"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-C",
              route_type: 0,
              stop: "70212"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "70211"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "71151"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "place-kencl"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-B",
              route_type: 0,
              stop: "70149"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-D",
              route_type: 0,
              stop: "71150"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70212"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "70211"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "Green-E",
              route_type: 0,
              stop: "place-smary"
            }
          ],
          lifecycle: "NEW",
          severity: 7,
          timeframe: nil,
          updated_at: ~U[2023-04-14 19:53:54Z],
          url: nil
        }
      ]

      wtc_alerts = [
        %Screens.Alerts.Alert{
          active_period: [{~U[2023-04-14 10:48:05Z], ~U[2023-04-14 16:53:05Z]}],
          cause: :unknown,
          created_at: ~U[2023-04-14 10:48:06Z],
          description: "Affected stops:\r\nSouth Station (outbound)\r\nCourthouse (outbound)\r\nWorld Trade Center (outbound)",
          effect: :detour,
          header: "Silver Line - SL1, Silver Line - SL2 and Silver Line - SL3 detoured",
          id: "137327",
          informed_entities: [
            %{
              direction_id: nil,
              facility: nil,
              route: "741",
              route_type: 3,
              stop: "74611"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "741",
              route_type: 3,
              stop: "74612"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "741",
              route_type: 3,
              stop: "74613"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "741",
              route_type: 3,
              stop: "place-crtst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "741",
              route_type: 3,
              stop: "place-sstat"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "741",
              route_type: 3,
              stop: "place-wtcst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "742",
              route_type: 3,
              stop: "74611"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "742",
              route_type: 3,
              stop: "74612"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "742",
              route_type: 3,
              stop: "74613"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "742",
              route_type: 3,
              stop: "place-crtst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "742",
              route_type: 3,
              stop: "place-sstat"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "742",
              route_type: 3,
              stop: "place-wtcst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "743",
              route_type: 3,
              stop: "74611"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "743",
              route_type: 3,
              stop: "74612"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "743",
              route_type: 3,
              stop: "74613"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "743",
              route_type: 3,
              stop: "place-crtst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "743",
              route_type: 3,
              stop: "place-sstat"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "743",
              route_type: 3,
              stop: "place-wtcst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "746",
              route_type: 3,
              stop: "74611"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "746",
              route_type: 3,
              stop: "74612"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "746",
              route_type: 3,
              stop: "74613"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "746",
              route_type: 3,
              stop: "place-crtst"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "746",
              route_type: 3,
              stop: "place-sstat"
            },
            %{
              direction_id: nil,
              facility: nil,
              route: "746",
              route_type: 3,
              stop: "place-wtcst"
            }
          ],
          lifecycle: "NEW",
          severity: 7,
          timeframe: nil,
          updated_at: ~U[2023-04-18 14:48:06Z],
          url: nil
        }
      ]

      kenmore_stop_sequences = [
        ["place-unsqu", "place-lech", "place-spmnl", "place-north", "place-haecl",
         "place-gover", "place-pktrm", "place-boyls", "place-armnl", "place-coecl",
         "place-hymnl", "place-kencl", "place-fenwy", "place-longw", "place-bvmnl",
         "place-brkhl", "place-bcnfd", "place-rsmnl", "place-chhil", "place-newto",
         "place-newtn", "place-eliot", "place-waban", "place-woodl", "place-river"],
        ["place-gover", "place-pktrm", "place-boyls", "place-armnl", "place-coecl",
         "place-hymnl", "place-kencl", "place-bland", "place-buest", "place-bucen",
         "place-amory", "place-babck", "place-brico", "place-harvd", "place-grigg",
         "place-alsgr", "place-wrnst", "place-wascm", "place-sthld", "place-chswk",
         "place-chill", "place-sougr", "place-lake"],
        ["place-gover", "place-pktrm", "place-boyls", "place-armnl", "place-coecl",
         "place-hymnl", "place-kencl", "place-smary", "place-hwsst", "place-kntst",
         "place-stpul", "place-cool", "place-sumav", "place-bndhl", "place-fbkst",
         "place-bcnwa", "place-tapst", "place-denrd", "place-engav", "place-clmnl"]
      ]

      wtc_stop_sequences = [
        ["place-sstat", "place-crtst", "place-wtcst", "place-conrd", "place-aport",
         "place-estav", "place-boxdt", "place-belsq", "place-chels"],
        ["place-sstat", "place-crtst", "place-wtcst", "place-conrd", "247", "30249",
         "30250"],
        ["place-sstat", "place-crtst", "place-wtcst", "place-conrd", "17091"]
      ]

      %{
        config_kenmore: config_kenmore,
        config_wtc: config_wtc,
        now: now,
        fetch_stop_name_fn: fn _ -> "Test" end,
        fetch_routes_by_stop_fn: fn
            "place-kencl", _, [:light_rail, :subway] -> {:ok, kenmore_routes}
            "place-wtcst", _, [:bus] -> {:ok, wtc_routes}
          end,
        kenmore_alerts: kenmore_alerts,
        wtc_alerts: wtc_alerts,
        fetch_parent_station_sequences_fn: fn
            "place-kencl", ["Green-B", "Green-C", "Green-D"] -> {:ok, kenmore_stop_sequences}
            "place-wtcst", ["741", "742", "743"] -> {:ok, wtc_stop_sequences}
          end
      }
    end

    test "serializes Kenmore special case: B / C, multiple alerts", context do
      alerts = Enum.drop(context.kenmore_alerts, -2)

      fetch_alerts_fn = fn route_ids: ["Green-B", "Green-C", "Green-D"] -> {:ok, alerts} end

      actual_widgets = DupAlerts.alert_instances(
        context.config_kenmore,
        context.now,
        context.fetch_stop_name_fn,
        context.fetch_routes_by_stop_fn,
        fetch_alerts_fn,
        context.fetch_parent_station_sequences_fn
      )

      expected_serialized_json = [
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Bost Coll/Clvlnd Cir"}]
          },
          color: :green
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: [
              "No",
              %{icon: "green_b"},
              %{format: :bold, text: "Bost Coll"},
              "or",
              %{icon: "green_c"},
              %{format: :bold, text: "Cleveland Cir"},
              "trains"
            ]
          },
          header: %{color: :green, text: "Kenmore"},
          remedy: %FreeTextLine{
            icon: :shuttle,
            text: [%{format: :bold, text: "Use shuttle bus"}]
          }
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Bost Coll/Clvlnd Cir"}]
          },
          color: :green
        }
      ]

      assert Enum.at(expected_serialized_json, 0) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 0))
      assert Enum.at(expected_serialized_json, 1) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 1))
      assert Enum.at(expected_serialized_json, 2) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 2))
    end

    test "serializes Kenmore special case: C / D, multiple alerts", context do
      alerts = context.kenmore_alerts
        |> Enum.drop(1)
        |> Enum.drop(-1)

      fetch_alerts_fn = fn route_ids: ["Green-B", "Green-C", "Green-D"] -> {:ok, alerts} end

      actual_widgets = DupAlerts.alert_instances(
        context.config_kenmore,
        context.now,
        context.fetch_stop_name_fn,
        context.fetch_routes_by_stop_fn,
        fetch_alerts_fn,
        context.fetch_parent_station_sequences_fn
      )

      expected_serialized_json = [
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Clvlnd Cir/Riverside"}]
          },
          color: :green
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: [
              "No",
              %{icon: "green_c"},
              %{format: :bold, text: "Cleveland Cir"},
              "or",
              %{icon: "green_d"},
              %{format: :bold, text: "Riverside"},
              "trains"
            ]
          },
          header: %{color: :green, text: "Kenmore"},
          remedy: %FreeTextLine{
            icon: :shuttle,
            text: [%{format: :bold, text: "Use shuttle bus"}]
          }
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Clvlnd Cir/Riverside"}]
          },
          color: :green
        }
      ]

      assert Enum.at(expected_serialized_json, 0) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 0))
      assert Enum.at(expected_serialized_json, 1) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 1))
      assert Enum.at(expected_serialized_json, 2) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 2))
    end

    test "serializes Kenmore special case: B / D, single alert ", context do
      alerts = [Enum.at(context.kenmore_alerts, 0)] ++ [Enum.at(context.kenmore_alerts, 2)]

      fetch_alerts_fn = fn route_ids: ["Green-B", "Green-C", "Green-D"] -> {:ok, alerts} end

      actual_widgets = DupAlerts.alert_instances(
        context.config_kenmore,
        context.now,
        context.fetch_stop_name_fn,
        context.fetch_routes_by_stop_fn,
        fetch_alerts_fn,
        context.fetch_parent_station_sequences_fn
      )

      expected_serialized_json = [
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Bost Coll / Riverside"}]
          },
          color: :green
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: [
              "No",
              %{icon: "green_b"},
              %{format: :bold, text: "Boston College"},
              "or",
              %{icon: "green_d"},
              %{format: :bold, text: "Riverside"},
              "trains"
            ]
          },
          header: %{color: :green, text: "Kenmore"},
          remedy: %FreeTextLine{
            icon: :shuttle,
            text: [%{format: :bold, text: "Use shuttle bus"}]
          }
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Bost Coll / Riverside"}]
          },
          color: :green
        }
      ]

      assert Enum.at(expected_serialized_json, 0) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 0))
      assert Enum.at(expected_serialized_json, 1) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 1))
      assert Enum.at(expected_serialized_json, 2) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 2))
    end

    test "serializes Kenmore special case: B / C / D, single alert", context do
      alerts = [Enum.at(context.kenmore_alerts, 3)]

      fetch_alerts_fn = fn route_ids: ["Green-B", "Green-C", "Green-D"] -> {:ok, alerts} end

      actual_widgets = DupAlerts.alert_instances(
        context.config_kenmore,
        context.now,
        context.fetch_stop_name_fn,
        context.fetch_routes_by_stop_fn,
        fetch_alerts_fn,
        context.fetch_parent_station_sequences_fn
      )

      expected_serialized_json = [
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Westbound"}, "trains"]
          },
          color: :green
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: [
              "No",
              %{icon: "green_b"},
              %{icon: "green_c"},
              %{icon: "green_d"},
              %{special: "break"},
              %{format: :bold, text: "Westbound"},
              "trains"
            ]
          },
          header: %{color: :green, text: "Kenmore"},
          remedy: %FreeTextLine{
            icon: :shuttle,
            text: [%{format: :bold, text: "Use shuttle bus"}]
          }
        },
        %{
          text: %FreeTextLine{
            icon: :warning,
            text: ["No", %{format: :bold, text: "Westbound"}, "trains"]
          },
          color: :green
        }
      ]

      assert Enum.at(expected_serialized_json, 0) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 0))
      assert Enum.at(expected_serialized_json, 1) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 1))
      assert Enum.at(expected_serialized_json, 2) == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 2))
    end

    test "serializes WTC special case: WTC is detoured", context do
      alerts = context.wtc_alerts

      fetch_alerts_fn = fn route_ids: ["741", "742", "743"] -> {:ok, alerts} end

      actual_widgets = DupAlerts.alert_instances(
        context.config_wtc,
        context.now,
        context.fetch_stop_name_fn,
        context.fetch_routes_by_stop_fn,
        fetch_alerts_fn,
        context.fetch_parent_station_sequences_fn
      )

      expected_serialized_json = %{
        text: %Screens.Config.V2.FreeTextLine{
          icon: :warning,
          text: ["Building closed"]
        },
        header: %{color: :silver, text: "World Trade Ctr"},
        remedy: %Screens.Config.V2.FreeTextLine{
          icon: :shuttle,
          text: [%{format: :bold, text: "Board Silver Line on street"}]
        }
      }

      assert expected_serialized_json == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 0))
      assert expected_serialized_json == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 1))
      assert expected_serialized_json == DupSpecialCaseAlert.serialize(Enum.at(actual_widgets, 2))
    end

  end
end