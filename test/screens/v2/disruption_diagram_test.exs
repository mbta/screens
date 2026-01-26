defmodule Screens.V2.DisruptionDiagramTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.TestSupport.DisruptionDiagramLocalizedAlert, as: DDAlert
  alias Screens.TestSupport.SubwayTaggedStopSequences, as: TaggedSeq
  alias Screens.V2.DisruptionDiagram, as: DD

  import Screens.TestSupport.ParentStationIdSigil

  describe "serialize/1" do
    #############
    # BLUE LINE #
    #############

    test "serializes a Blue Line shuttle" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :blue, ~P"mvbcl", {~P"wondl", ~P"mvbcl"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {4, 11},
        line: :blue,
        current_station_slot_index: 4,
        slots: [
          %{type: :terminal, label_id: ~P"bomnl"},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Aquarium", abbrev: "Aquarium"}, show_symbol: true},
          %{label: %{full: "Maverick", abbrev: "Maverick"}, show_symbol: true},
          %{label: %{full: "Airport", abbrev: "Airport"}, show_symbol: true},
          %{label: %{full: "Wood Island", abbrev: "Wood Island"}, show_symbol: true},
          %{label: %{full: "Orient Heights", abbrev: "Orient Hts"}, show_symbol: true},
          %{label: %{full: "Suffolk Downs", abbrev: "Suffolk Dns"}, show_symbol: true},
          %{label: %{full: "Beachmont", abbrev: "Beachmont"}, show_symbol: true},
          %{label: %{full: "Revere Beach", abbrev: "Revere Bch"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"wondl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Blue Line suspension" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :blue, ~P"gover", {~P"state", ~P"bomnl"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {0, 2},
        line: :blue,
        current_station_slot_index: 1,
        slots: [
          %{type: :terminal, label_id: ~P"bomnl"},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Aquarium", abbrev: "Aquarium"}, show_symbol: true},
          %{label: %{full: "Maverick", abbrev: "Maverick"}, show_symbol: true},
          %{label: %{full: "Airport", abbrev: "Airport"}, show_symbol: true},
          %{label: %{full: "Wood Island", abbrev: "Wood Island"}, show_symbol: true},
          %{label: %{full: "Orient Heights", abbrev: "Orient Hts"}, show_symbol: true},
          %{label: %{full: "Suffolk Downs", abbrev: "Suffolk Dns"}, show_symbol: true},
          %{label: %{full: "Beachmont", abbrev: "Beachmont"}, show_symbol: true},
          %{label: %{full: "Revere Beach", abbrev: "Revere Bch"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"wondl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Blue Line station closure" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :blue, ~P"wondl", ~P[mvbcl aport])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [4, 5],
        line: :blue,
        current_station_slot_index: 11,
        slots: [
          %{type: :terminal, label_id: ~P"bomnl"},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Aquarium", abbrev: "Aquarium"}, show_symbol: true},
          %{label: %{full: "Maverick", abbrev: "Maverick"}, show_symbol: true},
          %{label: %{full: "Airport", abbrev: "Airport"}, show_symbol: true},
          %{label: %{full: "Wood Island", abbrev: "Wood Island"}, show_symbol: true},
          %{label: %{full: "Orient Heights", abbrev: "Orient Hts"}, show_symbol: true},
          %{label: %{full: "Suffolk Downs", abbrev: "Suffolk Dns"}, show_symbol: true},
          %{label: %{full: "Beachmont", abbrev: "Beachmont"}, show_symbol: true},
          %{label: %{full: "Revere Beach", abbrev: "Revere Bch"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"wondl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Blue Line station closure at Government Center, which is also the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :blue, ~P"gover", [~P"gover"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [1],
        line: :blue,
        current_station_slot_index: 1,
        slots: [
          %{type: :terminal, label_id: ~P"bomnl"},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Aquarium", abbrev: "Aquarium"}, show_symbol: true},
          %{label: %{full: "Maverick", abbrev: "Maverick"}, show_symbol: true},
          %{label: %{full: "Airport", abbrev: "Airport"}, show_symbol: true},
          %{label: %{full: "Wood Island", abbrev: "Wood Island"}, show_symbol: true},
          %{label: %{full: "Orient Heights", abbrev: "Orient Hts"}, show_symbol: true},
          %{label: %{full: "Suffolk Downs", abbrev: "Suffolk Dns"}, show_symbol: true},
          %{label: %{full: "Beachmont", abbrev: "Beachmont"}, show_symbol: true},
          %{label: %{full: "Revere Beach", abbrev: "Revere Bch"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"wondl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    ###############
    # ORANGE LINE #
    ###############

    test "serializes an Orange Line trunk station closure at Downtown Crossing, which is also the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :orange, ~P"dwnxg", [~P"dwnxg"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [3],
        line: :orange,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"ogmnl"},
          # <padding>
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </padding>
          # <closure>
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes an Orange Line station closure far from home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :orange, ~P"sbmnl", [~P"welln"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [2],
        line: :orange,
        current_station_slot_index: 7,
        slots: [
          %{type: :terminal, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          %{label: %{full: "Assembly", abbrev: "Assembly"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Sullivan Square", abbrev: "Sullivan Sq"}, show_symbol: true},
          # Com College, North Sta, Haymarket, State, Downt'n Xng, Chinatown, Tufts Med, Back Bay, Mass Ave, Ruggles, Roxbury Xng
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          # </current_location>
          %{type: :terminal, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes an Orange Line suspension spanning most of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :orange, ~P"welln", {~P"astao", ~P"grnst"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {3, 10},
        line: :orange,
        current_station_slot_index: 2,
        slots: [
          %{type: :terminal, label_id: ~P"ogmnl"},
          # <current_location>
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          # </current_location>
          # <gap />
          # <closure>
          %{label: %{full: "Assembly", abbrev: "Assembly"}, show_symbol: true},
          %{label: %{full: "Sullivan Square", abbrev: "Sullivan Sq"}, show_symbol: true},
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          # Haymarket, State, Downt'n Xng, Chinatown, Tufts Med, Back Bay, Mass Ave, Ruggles, Roxbury Xng
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          # </closure>
          %{type: :terminal, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a long Orange Line shuttle some distance from the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :orange, ~P"mlmnl", {~P"ccmnl", ~P"grnst"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {4, 10},
        line: :orange,
        current_station_slot_index: 1,
        slots: [
          # <current_location>
          %{type: :terminal, label_id: ~P"ogmnl"},
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          # Assembly, Sullivan Sq
          %{label: "…", show_symbol: false},
          # </gap>
          # <closure>
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          #  State, Downt'n Xng, Chinatown, Tufts Med, Back Bay, Mass Ave, Ruggles, Roxbury Xng
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          #
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          # </closure>
          %{type: :terminal, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a short Orange Line shuttle close to the home stop, at one end of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :orange, ~P"rugg", {~P"jaksn", ~P"forhl"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {4, 7},
        line: :orange,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"ogmnl"},
          # <current_location>
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"forhl"}
          # </closure>
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a short Orange Line suspension some distance from the home stop, at one end of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :orange, ~P"tumnl", {~P"mlmnl", ~P"astao"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {1, 3},
        line: :orange,
        current_station_slot_index: 7,
        slots: [
          %{type: :terminal, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          %{label: %{full: "Assembly", abbrev: "Assembly"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Sullivan Square", abbrev: "Sullivan Sq"}, show_symbol: true},
          # Com College, North Sta, Haymarket, State, Downt'n Xng
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "Tufts Medical Center", abbrev: "Tufts Med"}, show_symbol: true},
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a long Orange Line suspension near the home stop, at one end of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :orange, ~P"sbmnl", {~P"ccmnl", ~P"rugg"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {1, 6},
        line: :orange,
        current_station_slot_index: 9,
        slots: [
          %{type: :arrow, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          # Haymarket, State, Downt'n Xng, Chinatown, Tufts Med
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          # </current_location>
          %{type: :terminal, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a long Orange Line shuttle some distance from the home stop, at one end of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :orange, ~P"rcmnl", {~P"mlmnl", ~P"chncl"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 6},
        line: :orange,
        current_station_slot_index: 9,
        slots: [
          %{type: :terminal, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          # Assembly, Sullivan Sq, Com College, North Sta, Haymarket
          %{label: "…", show_symbol: false},
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          # </closure>
          # <gap>
          # Tufts Med, Back Bay, Mass Ave
          %{label: "…", show_symbol: false},
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          # </gap
          # <current_location>
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a short Orange Line station closure near the home stop, around the middle of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :orange, ~P"tumnl", [~P"dwnxg"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [2],
        line: :orange,
        current_station_slot_index: 4,
        slots: [
          %{type: :arrow, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          # </closure>
          # <gap />
          # <current_location>
          %{label: %{full: "Tufts Medical Center", abbrev: "Tufts Med"}, show_symbol: true},
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          # <current_location>
          %{type: :arrow, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a medium Orange Line suspension some distance from the home stop, around the middle of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :orange, ~P"rcmnl", {~P"sull", ~P"dwnxg"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {1, 6},
        line: :orange,
        current_station_slot_index: 11,
        slots: [
          %{type: :arrow, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Sullivan Square", abbrev: "Sullivan Sq"}, show_symbol: true},
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          # Tufts Med, Back Bay
          %{label: "…", show_symbol: false},
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a long Orange Line shuttle containing the home stop, around the middle of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :orange, ~P"bbsta", {~P"sull", ~P"rugg"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 10},
        line: :orange,
        current_station_slot_index: 8,
        slots: [
          %{type: :arrow, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Sullivan Square", abbrev: "Sullivan Sq"}, show_symbol: true},
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # State, Downt'n Xng
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          %{label: %{full: "Tufts Medical Center", abbrev: "Tufts Med"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a long Orange Line station closure some distance from the home stop, near the middle of the line" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :orange, ~P"jaksn", [~P"astao", ~P"tumnl"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [2, 5],
        line: :orange,
        current_station_slot_index: 9,
        slots: [
          %{type: :arrow, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          %{label: %{full: "Assembly", abbrev: "Assembly"}, show_symbol: true},
          # Com College, North Sta, Haymarket, State, Downt'n Xng, Chinatown
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          %{label: %{full: "Tufts Medical Center", abbrev: "Tufts Med"}, show_symbol: true},
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          # </closure>
          # <gap>
          # Mass Ave, Ruggles
          %{label: "…", show_symbol: false},
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - trunk - L terminal - closure omission
    # Red - trunk - L terminal - gap and closure omission
    # Red - trunk - L arrow - gap omission
    # Red - trunk - L arrow - closure omission
    # Red - trunk - L arrow - gap and closure omission
    # ...
    # Red - trunk -arrows - no omissions (good opportunity to test padding small diagram away from JFK)

    ##################
    # RED LINE TRUNK #
    ##################

    test "serializes a Red Line trunk station closure at Downtown Crossing, which is also the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :red, ~P"dwnxg", [~P"dwnxg"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [3],
        line: :red,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          # <padding>
          %{label: %{full: "Charles/MGH", abbrev: "Charles/MGH"}, show_symbol: true},
          # </padding>
          # <closure>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - trunk - L terminal - no omission
    test "serializes a Red Line trunk shuttle near the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"portr", {~P"knncl", ~P"jfk"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {5, 12},
        line: :red,
        current_station_slot_index: 2,
        slots: [
          %{type: :terminal, label_id: ~P"alfcl"},
          # <current_location>
          %{label: %{full: "Davis", abbrev: "Davis"}, show_symbol: true},
          %{label: %{full: "Porter", abbrev: "Porter"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Harvard", abbrev: "Harvard"}, show_symbol: true},
          %{label: %{full: "Central", abbrev: "Central"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Kendall/MIT", abbrev: "Kendall/MIT"}, show_symbol: true},
          %{label: %{full: "Charles/MGH", abbrev: "Charles/MGH"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
          %{label: %{full: "Broadway", abbrev: "Broadway"}, show_symbol: true},
          %{label: %{full: "Andrew", abbrev: "Andrew"}, show_symbol: true},
          %{label: %{full: "JFK/UMass", abbrev: "JFK/UMass"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - trunk - L terminal - gap omission
    test "serializes a Red Line trunk station closure some distance from the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :red, ~P"jfk", ~P[davis portr])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [1, 2],
        line: :red,
        current_station_slot_index: 10,
        slots: [
          # <closure>
          %{type: :terminal, label_id: ~P"alfcl"},
          %{label: %{full: "Davis", abbrev: "Davis"}, show_symbol: true},
          %{label: %{full: "Porter", abbrev: "Porter"}, show_symbol: true},
          %{label: %{full: "Harvard", abbrev: "Harvard"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Central", abbrev: "Central"}, show_symbol: true},
          %{label: %{full: "Kendall/MIT", abbrev: "Kendall/MIT"}, show_symbol: true},
          # Charles/MGH, Park St, Downt'n Xng
          %{
            label: %{abbrev: "…via Downt'n Xng", full: "…via Downtown Crossing"},
            show_symbol: false
          },
          %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
          %{label: %{full: "Broadway", abbrev: "Broadway"}, show_symbol: true},
          %{label: %{full: "Andrew", abbrev: "Andrew"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "JFK/UMass", abbrev: "JFK/UMass"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - trunk - L terminal - no omission, with padding plan A
    test "serializes a short Red Line station closure next to the home stop, near Alewife" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :red, ~P"portr", [~P"davis"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [1],
        line: :red,
        current_station_slot_index: 2,
        slots: [
          # <closure>
          %{type: :terminal, label_id: ~P"alfcl"},
          %{label: %{full: "Davis", abbrev: "Davis"}, show_symbol: true},
          # <current_location>
          %{label: %{full: "Porter", abbrev: "Porter"}, show_symbol: true},
          # </closure>
          %{label: %{full: "Harvard", abbrev: "Harvard"}, show_symbol: true},
          # </current_location>
          # <padding>
          %{label: %{full: "Central", abbrev: "Central"}, show_symbol: true},
          # </padding>
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - trunk - L terminal - no omission, with padding plan B
    test "serializes a short Red Line station closure near the home stop, which is Alewife" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :red, ~P"alfcl", [~P"davis"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [1],
        line: :red,
        current_station_slot_index: 0,
        slots: [
          # <closure>
          # <current_location subsumed>
          %{type: :terminal, label_id: ~P"alfcl"},
          # </current_location>
          %{label: %{full: "Davis", abbrev: "Davis"}, show_symbol: true},
          %{label: %{full: "Porter", abbrev: "Porter"}, show_symbol: true},
          # </closure>
          # <padding>
          %{label: %{full: "Harvard", abbrev: "Harvard"}, show_symbol: true},
          %{label: %{full: "Central", abbrev: "Central"}, show_symbol: true},
          # </padding>
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - trunk - L terminal - no omission, with padding plan A and B
    test "serializes a short Red Line suspension including the home stop, which is Porter" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :red, ~P"portr", {~P"portr", ~P"harsq"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {2, 3},
        line: :red,
        current_station_slot_index: 2,
        slots: [
          %{type: :terminal, label_id: ~P"alfcl"},
          # <padding planA>
          %{label: %{full: "Davis", abbrev: "Davis"}, show_symbol: true},
          # </padding>
          # <closure>
          # <current_location subsumed>
          %{label: %{full: "Porter", abbrev: "Porter"}, show_symbol: true},
          %{label: %{full: "Harvard", abbrev: "Harvard"}, show_symbol: true},
          # </current_location>
          # </closure>
          # <padding planB>
          %{label: %{full: "Central", abbrev: "Central"}, show_symbol: true},
          # </padding>
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - trunk - L arrow - no omission
    test "serializes a Red Line trunk shuttle around the middle of the trunk" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"dwnxg", {~P"chmnl", ~P"sstat"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 4},
        line: :red,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          %{label: %{full: "Charles/MGH", abbrev: "Charles/MGH"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Red Line trunk shuttle with home stop at JFK" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"jfk", {~P"chmnl", ~P"sstat"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 4},
        line: :red,
        current_station_slot_index: 7,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          # <closure>
          %{label: %{full: "Charles/MGH", abbrev: "Charles/MGH"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Broadway", abbrev: "Broadway"}, show_symbol: true},
          %{label: %{full: "Andrew", abbrev: "Andrew"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "JFK/UMass", abbrev: "JFK/UMass"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"asmnl" <> "+" <> ~P"brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Red Line shuttle that crosses from trunk to Ashmont branch" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"smmnl", {~P"jfk", ~P"fldcr"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 3},
        line: :red,
        current_station_slot_index: 4,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          # <closure>
          %{label: %{abbrev: "JFK/UMass", full: "JFK/UMass"}, show_symbol: true},
          %{label: %{full: "Savin Hill", abbrev: "Savin Hill"}, show_symbol: true},
          %{label: %{full: "Fields Corner", abbrev: "Fields Cnr"}, show_symbol: true},
          # </closure>
          # <gap />
          # <current_location>
          %{label: %{full: "Shawmut", abbrev: "Shawmut"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"asmnl"}
          # </current_location>
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Red Line suspension that crosses from trunk to Braintree branch" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :red, ~P"dwnxg", {~P"jfk", ~P"brntn"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {6, 11},
        line: :red,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          # <current_location>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
          %{label: %{full: "Broadway", abbrev: "Broadway"}, show_symbol: true},
          %{label: %{full: "Andrew", abbrev: "Andrew"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "JFK/UMass", abbrev: "JFK/UMass"}, show_symbol: true},
          %{label: %{full: "North Quincy", abbrev: "N Quincy"}, show_symbol: true},
          %{label: %{full: "Wollaston", abbrev: "Wollaston"}, show_symbol: true},
          %{label: %{full: "Quincy Center", abbrev: "Quincy Ctr"}, show_symbol: true},
          %{label: %{full: "Quincy Adams", abbrev: "Quincy Adms"}, show_symbol: true},
          %{type: :terminal, label_id: "place-brntn"}
          # </closure>
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    ####################
    # RED LINE ASHMONT #
    ####################

    # Red - Ashmont - trunk alert with home stop on branch
    test "serializes a Red Line trunk suspension with home stop on the Ashmont branch" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"shmnl", {~P"chmnl", ~P"sstat"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 4},
        line: :red,
        current_station_slot_index: 8,
        slots: [
          %{type: :arrow, label_id: "place-alfcl"},
          # <closure>
          %{label: %{abbrev: "Charles/MGH", full: "Charles/MGH"}, show_symbol: true},
          %{label: %{abbrev: "Park St", full: "Park Street"}, show_symbol: true},
          %{label: %{abbrev: "Downt'n Xng", full: "Downtown Crossing"}, show_symbol: true},
          %{label: %{abbrev: "South Sta", full: "South Station"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{abbrev: "Broadway", full: "Broadway"}, show_symbol: true},
          %{label: %{abbrev: "Andrew", full: "Andrew"}, show_symbol: true},
          %{label: %{abbrev: "JFK/UMass", full: "JFK/UMass"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{abbrev: "Savin Hill", full: "Savin Hill"}, show_symbol: true},
          %{label: %{abbrev: "Fields Cnr", full: "Fields Corner"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: "place-asmnl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - Ashmont - branch alert with home stop on trunk
    test "serializes a Red Line Ashmont branch station closure with home stop on the trunk" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :red, ~P"portr", [~P"shmnl"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [7],
        line: :red,
        current_station_slot_index: 2,
        slots: [
          %{type: :terminal, label_id: "place-alfcl"},
          # <current_location>
          %{label: %{abbrev: "Davis", full: "Davis"}, show_symbol: true},
          %{label: %{abbrev: "Porter", full: "Porter"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{abbrev: "Harvard", full: "Harvard"}, show_symbol: true},
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{abbrev: "Andrew", full: "Andrew"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{abbrev: "JFK/UMass", full: "JFK/UMass"}, show_symbol: true},
          %{label: %{abbrev: "Savin Hill", full: "Savin Hill"}, show_symbol: true},
          %{label: %{abbrev: "Fields Cnr", full: "Fields Corner"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: "place-asmnl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Red Line Ashmont branch shuttle with home stop on the Ashmont branch" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"fldcr", {~P"shmnl", ~P"asmnl"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {2, 5},
        line: :red,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          # <padding>
          %{label: %{abbrev: "JFK/UMass", full: "JFK/UMass"}, show_symbol: true},
          # </padding>
          # <closure>
          %{label: %{full: "Savin Hill", abbrev: "Savin Hill"}, show_symbol: true},
          %{label: %{full: "Fields Corner", abbrev: "Fields Cnr"}, show_symbol: true},
          %{label: %{full: "Shawmut", abbrev: "Shawmut"}, show_symbol: true},
          # <current_location subsumed>
          %{type: :terminal, label_id: ~P"asmnl"}
          # </current_location>
          # </closure>
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Red Line trunk station closure with home stop on the Ashmont branch" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :red, ~P"asmnl", [~P"chmnl"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [2],
        line: :red,
        current_station_slot_index: 9,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          # <closure>
          %{label: %{full: "Kendall/MIT", abbrev: "Kendall/MIT"}, show_symbol: true},
          %{label: %{full: "Charles/MGH", abbrev: "Charles/MGH"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "South Station", abbrev: "South Sta"}, show_symbol: true},
          %{label: "…", show_symbol: false},
          %{label: %{full: "Fields Corner", abbrev: "Fields Cnr"}, show_symbol: true},
          %{label: %{full: "Shawmut", abbrev: "Shawmut"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{type: :terminal, label_id: ~P"asmnl"}
          # </current_location>
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    ######################
    # RED LINE BRAINTREE #
    ######################

    # Red - Braintree - trunk alert with home stop on branch
    test "serializes a Red Line trunk suspension with home stop on the Braintree branch" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"wlsta", {~P"chmnl", ~P"sstat"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 4},
        line: :red,
        current_station_slot_index: 9,
        slots: [
          %{type: :arrow, label_id: "place-alfcl"},
          # <closure>
          %{label: %{abbrev: "Charles/MGH", full: "Charles/MGH"}, show_symbol: true},
          %{label: %{abbrev: "Park St", full: "Park Street"}, show_symbol: true},
          %{label: %{abbrev: "Downt'n Xng", full: "Downtown Crossing"}, show_symbol: true},
          %{label: %{abbrev: "South Sta", full: "South Station"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{abbrev: "Broadway", full: "Broadway"}, show_symbol: true},
          %{label: %{abbrev: "Andrew", full: "Andrew"}, show_symbol: true},
          %{label: %{abbrev: "JFK/UMass", full: "JFK/UMass"}, show_symbol: true},
          %{label: %{abbrev: "N Quincy", full: "North Quincy"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{abbrev: "Wollaston", full: "Wollaston"}, show_symbol: true},
          %{label: %{abbrev: "Quincy Ctr", full: "Quincy Center"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: "place-brntn"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - Braintree - branch alert with home stop on trunk
    test "serializes a Red Line Braintree branch station closure with home stop on the trunk" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :red, ~P"portr", [~P"qamnl"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [8],
        line: :red,
        current_station_slot_index: 2,
        slots: [
          %{label_id: "place-alfcl", type: :terminal},
          %{label: %{abbrev: "Davis", full: "Davis"}, show_symbol: true},
          %{label: %{abbrev: "Porter", full: "Porter"}, show_symbol: true},
          %{label: %{abbrev: "Harvard", full: "Harvard"}, show_symbol: true},
          %{label: %{abbrev: "Central", full: "Central"}, show_symbol: true},
          %{
            label: %{abbrev: "…via Downt'n Xng", full: "…via Downtown Crossing"},
            show_symbol: false
          },
          %{label: %{abbrev: "Wollaston", full: "Wollaston"}, show_symbol: true},
          %{label: %{abbrev: "Quincy Ctr", full: "Quincy Center"}, show_symbol: true},
          %{label: %{abbrev: "Quincy Adms", full: "Quincy Adams"}, show_symbol: true},
          %{label_id: "place-brntn", type: :terminal}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    # Red - Braintree - branch alert with home stop on branch
    test "serializes a Red Line Braintree branch shuttle with home stop on the Braintree branch" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :red, ~P"nqncy", {~P"nqncy", ~P"brntn"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {2, 6},
        line: :red,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"alfcl"},
          # <current_location>
          %{label: %{full: "JFK/UMass", abbrev: "JFK/UMass"}, show_symbol: true},
          # <closure>
          %{label: %{full: "North Quincy", abbrev: "N Quincy"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "Wollaston", abbrev: "Wollaston"}, show_symbol: true},
          %{label: %{full: "Quincy Center", abbrev: "Quincy Ctr"}, show_symbol: true},
          %{label: %{full: "Quincy Adams", abbrev: "Quincy Adms"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"brntn"}
          # </closure>
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    #####################
    # RED LINE MATTAPAN #
    #####################

    test "serializes a Mattapan Trolley shuttle" do
      localized_alert =
        DDAlert.make_localized_alert(
          :shuttle,
          :mattapan,
          ~P"asmnl",
          {~P"cenav", ~P"capst"}
        )

      expected = %{
        current_station_slot_index: 0,
        effect: :shuttle,
        effect_region_slot_index_range: {4, 6},
        line: :mattapan,
        slots: [
          %{label_id: ~P"asmnl", type: :terminal},
          %{label: %{abbrev: "Cedar Grove", full: "Cedar Grove"}, show_symbol: true},
          %{label: %{abbrev: "Butler", full: "Butler"}, show_symbol: true},
          %{label: %{abbrev: "Milton", full: "Milton"}, show_symbol: true},
          %{label: %{abbrev: "Central Ave", full: "Central Avenue"}, show_symbol: true},
          %{label: %{abbrev: "Valley Rd", full: "Valley Road"}, show_symbol: true},
          %{label: %{abbrev: "Capen St", full: "Capen Street"}, show_symbol: true},
          %{label_id: ~P"matt", type: :terminal}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    ####################
    # GREEN LINE TRUNK #
    ####################

    test "serializes a Green Line trunk station closure at Government Center, which is also the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :green, ~P"gover", [~P"gover"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [3],
        line: :green,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"coecl" <> "+west"},
          # <padding>
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          # </padding>
          # <closure>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"mdftf" <> "+" <> ~P"unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Green Line trunk station closure at North Station, which is also the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :green, ~P"north", [~P"north"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [3],
        line: :green,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"coecl" <> "+west"},
          # <padding>
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          # </padding>
          # <closure>
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "Science Park/West End", abbrev: "Science Pk"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"mdftf" <> "+" <> ~P"unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Green Line trunk suspension with home stop on the trunk" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :green, ~P"north", {~P"haecl", ~P"pktrm"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {1, 3},
        line: :green,
        current_station_slot_index: 4,
        slots: [
          %{type: :arrow, label_id: ~P"coecl" <> "+west"},
          # <closure>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </closure>
          # <gap />
          # <current_location>
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Science Park/West End", abbrev: "Science Pk"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"mdftf" <> "+" <> ~P"unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes the same alert viewed from home stop at Union Square" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :green, ~P"unsqu", {~P"haecl", ~P"pktrm"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {4, 6},
        line: :green,
        current_station_slot_index: 0,
        slots: [
          # <current_location>
          %{type: :terminal, label_id: ~P"unsqu"},
          # </current_location>
          # <gap>
          %{label: %{full: "Lechmere", abbrev: "Lechmere"}, show_symbol: true},
          %{label: %{full: "Science Park/West End", abbrev: "Science Pk"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"river"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes the same alert viewed from home stop on Medford branch" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :green, ~P"gilmn", {~P"haecl", ~P"pktrm"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {6, 8},
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"mdftf"},
          # <current_location>
          %{label: %{full: "Magoun Square", abbrev: "Magoun Sq"}, show_symbol: true},
          %{label: %{full: "Gilman Square", abbrev: "Gilman Sq"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "East Somerville", abbrev: "E Somerville"}, show_symbol: true},
          # Lechmere, Science Pk
          %{label: "…", show_symbol: false},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"hsmnl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes the same alert viewed from home stop on Riverside branch" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :green, ~P"fenwy", {~P"haecl", ~P"pktrm"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {6, 8},
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"river"},
          # <current_location>
          %{label: %{full: "Longwood", abbrev: "Longwood"}, show_symbol: true},
          %{label: %{full: "Fenway", abbrev: "Fenway"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Kenmore", abbrev: "Kenmore"}, show_symbol: true},
          %{label: %{full: "…via Copley", abbrev: "…via Copley"}, show_symbol: false},
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes the same alert viewed from home stop on Heath Street branch" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :green, ~P"symcl", {~P"haecl", ~P"pktrm"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {6, 8},
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"hsmnl"},
          # <current_location>
          %{label: %{full: "Northeastern University", abbrev: "Northeast'n"}, show_symbol: true},
          %{label: %{full: "Symphony", abbrev: "Symphony"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Prudential", abbrev: "Prudential"}, show_symbol: true},
          %{label: "…", show_symbol: false},
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"mdftf"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a trunk alert that does not extend past Government Center when home stop is on Boston College branch" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :green, ~P"amory", {~P"boyls", ~P"coecl"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {6, 8},
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"lake"},
          # <current_location>
          %{label: %{full: "Babcock Street", abbrev: "Babcock St"}, show_symbol: true},
          %{label: %{full: "Amory Street", abbrev: "Amory St"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Boston University Central", abbrev: "BU Central"}, show_symbol: true},
          %{label: %{full: "…via Kenmore", abbrev: "…via Kenmore"}, show_symbol: false},
          %{label: %{full: "Hynes Convention Center", abbrev: "Hynes"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Copley", abbrev: "Copley"}, show_symbol: true},
          %{label: %{full: "Arlington", abbrev: "Arlington"}, show_symbol: true},
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"gover"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a trunk alert that does not extend past Government Center when home stop is on Cleveland Circle branch" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :green, ~P"cool", {~P"boyls", ~P"coecl"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {6, 8},
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"clmnl"},
          # <current_location>
          %{label: %{full: "Summit Avenue", abbrev: "Summit Ave"}, show_symbol: true},
          %{label: %{full: "Coolidge Corner", abbrev: "Coolidge Cn"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Saint Paul Street", abbrev: "St. Paul St"}, show_symbol: true},
          %{label: %{full: "…via Kenmore", abbrev: "…via Kenmore"}, show_symbol: false},
          %{label: %{full: "Hynes Convention Center", abbrev: "Hynes"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Copley", abbrev: "Copley"}, show_symbol: true},
          %{label: %{full: "Arlington", abbrev: "Arlington"}, show_symbol: true},
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"gover"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "uses 'Kenmore & West' label for a Green Line trunk alert extending past Copley but not Kenmore" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :green, ~P"coecl", {~P"haecl", ~P"pktrm"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {5, 7},
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"kencl+west"},
          # <current_location>
          %{label: %{full: "Hynes Convention Center", abbrev: "Hynes"}, show_symbol: true},
          %{label: %{full: "Copley", abbrev: "Copley"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Arlington", abbrev: "Arlington"}, show_symbol: true},
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"mdftf" <> "+" <> ~P"unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    #######################
    # GREEN LINE BRANCHES #
    #######################

    test "serializes a Medford branch alert" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :green, ~P"gilmn", [~P"mgngl"])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [2],
        line: :green,
        current_station_slot_index: 3,
        slots: [
          %{type: :terminal, label_id: ~P"mdftf"},
          %{label: %{full: "Ball Square", abbrev: "Ball Sq"}, show_symbol: true},
          %{label: %{full: "Magoun Square", abbrev: "Magoun Sq"}, show_symbol: true},
          %{label: %{full: "Gilman Square", abbrev: "Gilman Sq"}, show_symbol: true},
          %{label: %{full: "East Somerville", abbrev: "E Somerville"}, show_symbol: true},
          %{type: :arrow, label_id: ~P"hsmnl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Union Square branch alert" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :green, ~P"unsqu", {~P"unsqu", ~P"lech"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {0, 1},
        line: :green,
        current_station_slot_index: 0,
        slots: [
          %{type: :terminal, label_id: ~P"unsqu"},
          %{label: %{full: "Lechmere", abbrev: "Lechmere"}, show_symbol: true},
          %{label: %{full: "Science Park/West End", abbrev: "Science Pk"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          %{type: :arrow, label_id: ~P"river"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Boston College branch alert" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :green, ~P"sthld", {~P"babck", ~P"alsgr"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {5, 9},
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"lake"},
          # <current_location>
          %{label: %{full: "Chiswick Road", abbrev: "Chiswick Rd"}, show_symbol: true},
          %{label: %{full: "Sutherland Road", abbrev: "Sutherland"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Washington Street", abbrev: "Washington"}, show_symbol: true},
          %{label: %{full: "Warren Street", abbrev: "Warren St"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Allston Street", abbrev: "Allston St"}, show_symbol: true},
          %{label: %{full: "Griggs Street", abbrev: "Griggs St"}, show_symbol: true},
          %{label: %{full: "Harvard Avenue", abbrev: "Harvard Ave"}, show_symbol: true},
          %{label: %{full: "Packards Corner", abbrev: "Packards Cn"}, show_symbol: true},
          %{label: %{full: "Babcock Street", abbrev: "Babcock St"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"gover"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Cleveland Circle branch alert" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :green, ~P"cool", {~P"sumav", ~P"bndhl"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 2},
        line: :green,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"clmnl"},
          # <closure>
          %{label: %{full: "Brandon Hall", abbrev: "Brandon Hll"}, show_symbol: true},
          %{label: %{full: "Summit Avenue", abbrev: "Summit Ave"}, show_symbol: true},
          # </closure>
          # <current_location>
          %{label: %{full: "Coolidge Corner", abbrev: "Coolidge Cn"}, show_symbol: true},
          %{label: %{full: "Saint Paul Street", abbrev: "St. Paul St"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"gover"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Riverside branch alert" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :green, ~P"rsmnl", {~P"chhil", ~P"newto"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 2},
        line: :green,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: ~P"river"},
          # <closure>
          %{label: %{full: "Newton Centre", abbrev: "Newton Ctr"}, show_symbol: true},
          %{label: %{full: "Chestnut Hill", abbrev: "Chestnut Hl"}, show_symbol: true},
          # </closure>
          # <current_location>
          %{label: %{full: "Reservoir", abbrev: "Reservoir"}, show_symbol: true},
          %{label: %{full: "Beaconsfield", abbrev: "B'consfield"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Heath Street branch alert" do
      localized_alert =
        DDAlert.make_localized_alert(:suspension, :green, ~P"symcl", {~P"brmnl", ~P"hsmnl"})

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {0, 5},
        line: :green,
        current_station_slot_index: 9,
        slots: [
          # <closure>
          %{type: :terminal, label_id: ~P"hsmnl"},
          %{label: %{full: "Back of the Hill", abbrev: "Back o'Hill"}, show_symbol: true},
          %{label: %{full: "Riverway", abbrev: "Riverway"}, show_symbol: true},
          %{label: %{full: "Mission Park", abbrev: "Mission Pk"}, show_symbol: true},
          %{label: %{full: "Fenwood Road", abbrev: "Fenwood Rd"}, show_symbol: true},
          %{label: %{full: "Brigham Circle", abbrev: "Brigham Cir"}, show_symbol: true},
          # </closure>
          # <gap>
          %{label: %{full: "Longwood Medical Area", abbrev: "Lngwd Med"}, show_symbol: true},
          %{label: %{full: "Museum of Fine Arts", abbrev: "MFA"}, show_symbol: true},
          %{label: %{full: "Northeastern University", abbrev: "Northeast'n"}, show_symbol: true},
          # </gap>
          # <current_location>
          %{label: %{full: "Symphony", abbrev: "Symphony"}, show_symbol: true},
          %{label: %{full: "Prudential", abbrev: "Prudential"}, show_symbol: true},
          # </current_location>
          %{type: :arrow, label_id: ~P"mdftf"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "serializes a Cleveland Circle branch alert with home stop at Government Center" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :green, ~P"gover", {~P"smary", ~P"cool"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 5},
        line: :green,
        current_station_slot_index: 11,
        slots: [
          %{type: :arrow, label_id: ~P"clmnl"},
          %{label: %{full: "Coolidge Corner", abbrev: "Coolidge Cn"}, show_symbol: true},
          %{label: %{full: "Saint Paul Street", abbrev: "St. Paul St"}, show_symbol: true},
          %{label: %{full: "Kent Street", abbrev: "Kent St"}, show_symbol: true},
          %{label: %{full: "Hawes Street", abbrev: "Hawes St"}, show_symbol: true},
          %{label: %{full: "Saint Mary's Street", abbrev: "St. Mary's"}, show_symbol: true},
          %{label: %{full: "Kenmore", abbrev: "Kenmore"}, show_symbol: true},
          %{label: %{full: "Hynes Convention Center", abbrev: "Hynes"}, show_symbol: true},
          %{
            label: %{full: "…via Copley", abbrev: "…via Copley"},
            show_symbol: false
          },
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"gover"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    ##############
    # VALIDATION #
    ##############

    test "rejects irrelevant alert effects" do
      delay_scenario = %{
        alert: %Alert{effect: :delay, informed_entities: [%{route: "Orange", stop: ~P"rugg"}]},
        location_context: %LocationContext{
          home_stop: ~P"bbsta",
          tagged_stop_sequences: TaggedSeq.orange()
        }
      }

      assert {:error, "invalid effect: delay"} = DD.serialize(delay_scenario)
    end

    test "rejects whole-route alerts" do
      whole_route_scenario = %{
        alert: %Alert{
          effect: :suspension,
          informed_entities: [%{route: "Orange", stop: nil, direction_id: nil}]
        },
        location_context: %LocationContext{
          home_stop: ~P"bbsta",
          tagged_stop_sequences: TaggedSeq.orange()
        }
      }

      assert {:error, "alert informs an entire route"} = DD.serialize(whole_route_scenario)
    end

    test "rejects shuttle and suspension alerts that inform only one stop" do
      one_stop_shuttle =
        DDAlert.make_localized_alert(:shuttle, :blue, ~P"gover", {~P"mvbcl", ~P"mvbcl"})

      assert {:error, "shuttle alert does not inform at least 2 stops"} =
               DD.serialize(one_stop_shuttle)

      one_stop_suspension =
        DDAlert.make_localized_alert(:suspension, :green, ~P"north", {~P"kencl", ~P"kencl"})

      assert {:error, "suspension alert does not inform at least 2 stops"} =
               DD.serialize(one_stop_suspension)
    end

    test "rejects alerts that inform multiple lines and can't be filtered to one line" do
      multi_line_scenario = %{
        alert: %Alert{
          effect: :station_closure,
          informed_entities: [
            %{route: "Blue", stop: ~P"gover"}
            | Enum.map(~w[B C D E], &%{route: "Green-#{&1}", stop: ~P"gover"})
          ]
        },
        location_context: %LocationContext{
          home_stop: ~P"gover",
          tagged_stop_sequences: Map.merge(TaggedSeq.blue(), TaggedSeq.green()),
          routes: [
            %{route_id: "Blue", active?: true}
            | Enum.map(~w[B C D E], &%{route_id: "Green-#{&1}", active?: true})
          ]
        }
      }

      assert {:error,
              "alert does not inform exactly one subway line, and home stop location does not help us choose one of the informed lines"} =
               DD.serialize(multi_line_scenario)
    end

    test "rejects alerts whose informed stops do not all lay along one stop sequence" do
      branched_scenario = %{
        alert: %Alert{
          effect: :station_closure,
          informed_entities: [
            %{route: "Green-D", stop: ~P"unsqu"},
            %{route: "Green-E", stop: ~P"mdftf"}
          ]
        },
        location_context: %LocationContext{
          home_stop: ~P"gover",
          tagged_stop_sequences: TaggedSeq.green()
        }
      }

      assert {:error, "no stop sequence contains both the home stop and all informed stops"} =
               DD.serialize(branched_scenario)
    end

    test "rejects alerts whose informed stops include a branch that's not directly reachable from the home stop" do
      unreachable_branch_scenario = %{
        alert: %Alert{
          effect: :shuttle,
          informed_entities: [
            %{route: "Green-E", stop: ~P"coecl"},
            %{route: "Green-E", stop: ~P"prmnl"},
            %{route: "Green-E", stop: ~P"symcl"}
          ]
        },
        location_context: %LocationContext{
          home_stop: ~P"unsqu",
          tagged_stop_sequences: TaggedSeq.green([:d])
        }
      }

      assert {:error, "no stop sequence contains both the home stop and all informed stops"} =
               DD.serialize(unreachable_branch_scenario)
    end

    ##############
    # EDGE CASES #
    ##############

    test "serializes an alert informing 2 lines when home stop is served by only one of the informed lines (BL)" do
      multi_line_scenario = %{
        alert: %Alert{
          effect: :station_closure,
          informed_entities: [
            %{route: "Blue", stop: ~P"gover"}
            | Enum.map(~w[B C D E], &%{route: "Green-#{&1}", stop: ~P"gover"})
          ]
        },
        location_context: %LocationContext{
          home_stop: ~P"wondl",
          tagged_stop_sequences: Map.merge(TaggedSeq.blue(), TaggedSeq.green()),
          routes: [%{route_id: "Blue", active?: true}]
        }
      }

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [1],
        line: :blue,
        current_station_slot_index: 11,
        slots: [
          %{type: :terminal, label_id: ~P"bomnl"},
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Aquarium", abbrev: "Aquarium"}, show_symbol: true},
          %{label: %{full: "Maverick", abbrev: "Maverick"}, show_symbol: true},
          %{label: %{full: "Airport", abbrev: "Airport"}, show_symbol: true},
          %{label: %{full: "Wood Island", abbrev: "Wood Island"}, show_symbol: true},
          %{label: %{full: "Orient Heights", abbrev: "Orient Hts"}, show_symbol: true},
          %{label: %{full: "Suffolk Downs", abbrev: "Suffolk Dns"}, show_symbol: true},
          %{label: %{full: "Beachmont", abbrev: "Beachmont"}, show_symbol: true},
          %{label: %{full: "Revere Beach", abbrev: "Revere Bch"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"wondl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(multi_line_scenario)

      assert expected == actual
    end

    test "serializes an alert informing 2 lines when home stop is served by only one of the informed lines (GL)" do
      multi_line_scenario = %{
        alert: %Alert{
          effect: :station_closure,
          informed_entities: [
            %{route: "Blue", stop: ~P"gover"}
            | Enum.map(~w[B C D E], &%{route: "Green-#{&1}", stop: ~P"gover"})
          ]
        },
        location_context: %LocationContext{
          home_stop: ~P"pktrm",
          tagged_stop_sequences: Map.merge(TaggedSeq.red(), TaggedSeq.green()),
          routes: [
            %{route_id: "Red", active?: true}
            | Enum.map(~w[B C D E], &%{route_id: "Green-#{&1}", active?: true})
          ]
        }
      }

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [3],
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"coecl" <> "+west"},
          # <current_location>
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          # <closure>
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "Government Center", abbrev: "Gov't Ctr"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: ~P"mdftf" <> "+" <> ~P"unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(multi_line_scenario)

      assert expected == actual
    end

    test "serializes an alert informing 2 lines when home stop is served by only one of the informed lines (GL branch)" do
      multi_line_scenario = %{
        alert: %Alert{
          effect: :station_closure,
          informed_entities: [
            %{route: "Red", stop: ~P"pktrm"}
            | Enum.map(~w[B C D E], &%{route: "Green-#{&1}", stop: ~P"pktrm"})
          ]
        },
        location_context: %LocationContext{
          home_stop: ~P"bucen",
          tagged_stop_sequences: TaggedSeq.green([:b]),
          routes: [%{route_id: "Green-B", active?: true}]
        }
      }

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [8],
        line: :green,
        current_station_slot_index: 2,
        slots: [
          %{type: :arrow, label_id: ~P"lake"},
          # <current_location>
          %{label: %{full: "Amory Street", abbrev: "Amory St"}, show_symbol: true},
          %{label: %{full: "Boston University Central", abbrev: "BU Central"}, show_symbol: true},
          # </current_location>
          # <gap>
          %{label: %{full: "Boston University East", abbrev: "BU East"}, show_symbol: true},
          %{label: %{full: "Blandford Street", abbrev: "Blandford"}, show_symbol: true},
          # Kenmore, Hynes, Copley
          %{
            label: %{full: "…via Kenmore & Copley", abbrev: "…via Kenmore & Copley"},
            show_symbol: false
          },
          %{label: %{full: "Arlington", abbrev: "Arlington"}, show_symbol: true},
          # </gap>
          # <closure>
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"gover"}
          # </closure>
        ]
      }

      assert {:ok, actual} = DD.serialize(multi_line_scenario)

      assert expected == actual
    end

    test "does not omit from an alert that spans 9 stops and contains the home stop" do
      # In this case, the closure has more than 8 slots available to it and doesn't get shrunk.
      localized_alert =
        DDAlert.make_localized_alert(
          :suspension,
          :orange,
          ~P"haecl",
          {~P"ccmnl", ~P"masta"}
        )

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {1, 9},
        line: :orange,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: "place-ogmnl"},
          # <closure>
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          %{label: %{full: "Tufts Medical Center", abbrev: "Tufts Med"}, show_symbol: true},
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: "place-forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "does not omit from an alert that spans 10 stops and contains the home stop" do
      # In this case, the closure has more than 8 slots available to it and doesn't get shrunk.
      localized_alert =
        DDAlert.make_localized_alert(
          :suspension,
          :orange,
          ~P"haecl",
          {~P"ccmnl", ~P"rugg"}
        )

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {1, 10},
        line: :orange,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: "place-ogmnl"},
          # <closure>
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: %{full: "Chinatown", abbrev: "Chinatown"}, show_symbol: true},
          %{label: %{full: "Tufts Medical Center", abbrev: "Tufts Med"}, show_symbol: true},
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: "place-forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "omits from an alert that spans more than 10 stops and contains the home stop" do
      # The largest a closure can possibly be is 10 slots.
      localized_alert =
        DDAlert.make_localized_alert(
          :suspension,
          :orange,
          ~P"haecl",
          {~P"ccmnl", ~P"rcmnl"}
        )

      expected = %{
        effect: :suspension,
        effect_region_slot_index_range: {1, 10},
        line: :orange,
        current_station_slot_index: 3,
        slots: [
          %{type: :arrow, label_id: "place-ogmnl"},
          # <closure>
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          # <current_location subsumed>
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "State", abbrev: "State"}, show_symbol: true},
          #
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          # Chinatown, Tufts Med
          %{label: "…", show_symbol: false},
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          # </closure>
          %{type: :arrow, label_id: "place-forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "for long shuttles with home stop near the middle, omits stops off-center to avoid omitting the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:shuttle, :orange, ~P"bbsta", {~P"mlmnl", ~P"grnst"})

      expected = %{
        effect: :shuttle,
        effect_region_slot_index_range: {1, 10},
        line: :orange,
        current_station_slot_index: 4,
        slots: [
          %{type: :terminal, label_id: ~P"ogmnl"},
          # <closure>
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          # Assembly, Sullivan Sq, Com College, North Sta, Haymarket, State, Downt'n Xng, Chinatown, Tufts Med
          # (Shifted left 3 to avoid omitting home stop at Back Bay)
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          # <current_location subsumed>
          %{label: %{full: "Back Bay", abbrev: "Back Bay"}, show_symbol: true},
          %{label: %{full: "Massachusetts Avenue", abbrev: "Mass Ave"}, show_symbol: true},
          # </current_location>
          %{label: %{full: "Ruggles", abbrev: "Ruggles"}, show_symbol: true},
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          # </closure>
          %{type: :terminal, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "for long station closures with closures near the middle, omits stops off-center to avoid omitting the home stop" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :orange, ~P"welln", ~P[mlmnl haecl grnst])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [1, 7, 10],
        line: :orange,
        current_station_slot_index: 2,
        slots: [
          %{type: :terminal, label_id: ~P"ogmnl"},
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          %{label: %{full: "Assembly", abbrev: "Assembly"}, show_symbol: true},
          %{label: %{full: "Sullivan Square", abbrev: "Sullivan Sq"}, show_symbol: true},
          %{label: %{full: "Community College", abbrev: "Com College"}, show_symbol: true},
          %{label: %{full: "North Station", abbrev: "North Sta"}, show_symbol: true},
          %{label: %{full: "Haymarket", abbrev: "Haymarket"}, show_symbol: true},
          # State, Downt'n Xng, Chinatown, Tufts Med, Back Bay, Mass Ave, Ruggles, Roxbury Xng, Jackson Sq
          %{
            label: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
            show_symbol: false
          },
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          %{type: :terminal, label_id: ~P"forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "splits omission around an important stop when necessary" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :orange, ~P"welln", ~P[mlmnl dwnxg grnst])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [1, 5, 10],
        line: :orange,
        current_station_slot_index: 2,
        slots: [
          %{type: :terminal, label_id: "place-ogmnl"},
          %{label: %{full: "Malden Center", abbrev: "Malden Ctr"}, show_symbol: true},
          %{label: %{full: "Wellington", abbrev: "Wellington"}, show_symbol: true},
          %{label: %{full: "Assembly", abbrev: "Assembly"}, show_symbol: true},
          %{label: "…", show_symbol: false},
          %{label: %{full: "Downtown Crossing", abbrev: "Downt'n Xng"}, show_symbol: true},
          %{label: "…", show_symbol: false},
          %{label: %{full: "Roxbury Crossing", abbrev: "Roxbury Xng"}, show_symbol: true},
          %{label: %{full: "Jackson Square", abbrev: "Jackson Sq"}, show_symbol: true},
          %{label: %{full: "Stony Brook", abbrev: "Stony Brook"}, show_symbol: true},
          %{label: %{full: "Green Street", abbrev: "Green St"}, show_symbol: true},
          %{type: :terminal, label_id: "place-forhl"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    test "absolute worst case scenario--split omission + gap omission" do
      localized_alert =
        DDAlert.make_localized_alert(:station_closure, :green, ~P"unsqu", ~P[boyls brkhl waban])

      expected = %{
        effect: :station_closure,
        closed_station_slot_indices: [2, 4, 7],
        line: :green,
        current_station_slot_index: 11,
        slots: [
          %{type: :terminal, label_id: "place-river"},
          %{label: %{full: "Woodland", abbrev: "Woodland"}, show_symbol: true},
          %{label: %{full: "Waban", abbrev: "Waban"}, show_symbol: true},
          %{label: "…", show_symbol: false},
          %{label: %{full: "Brookline Hills", abbrev: "B'kline Hls"}, show_symbol: true},
          %{
            label: %{full: "…via Kenmore & Copley", abbrev: "…via Kenmore & Copley"},
            show_symbol: false
          },
          %{label: %{full: "Arlington", abbrev: "Arlington"}, show_symbol: true},
          %{label: %{full: "Boylston", abbrev: "Boylston"}, show_symbol: true},
          %{label: %{full: "Park Street", abbrev: "Park St"}, show_symbol: true},
          %{label: "…", show_symbol: false},
          %{label: %{full: "Lechmere", abbrev: "Lechmere"}, show_symbol: true},
          %{type: :terminal, label_id: "place-unsqu"}
        ]
      }

      assert {:ok, actual} = DD.serialize(localized_alert)

      assert expected == actual
    end

    ###########
    # FAILURE #
    ###########

    test "fails to serialize a station closure that's impossible to fit without omitting an important stop" do
      localized_alert =
        DDAlert.make_localized_alert(
          :station_closure,
          :orange,
          ~P"welln",
          ~P[mlmnl astao ccmnl haecl dwnxg tumnl masta rcmnl sbmnl]
        )

      expected =
        {:error, "can't omit 9 from closure region without omitting at least one important stop"}

      assert expected == DD.serialize(localized_alert)
    end
  end
end
