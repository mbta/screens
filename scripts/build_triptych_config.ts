/**
 * This script provides some type checking and "spell-checking" on triptych config entries, and lets you skip duplicating all of the common bits of JSON.
 * To use, go to https://www.typescriptlang.org/play and paste this whole thing in, then hit "Run".
 * You may first need to click "TS Config"  and set Target to ES2019 or later.
 *
 * The resulting JSON will be printed to the console. It will be an object with two top-level fields:
 * - `screenConfig`: the main configuration for all of the triptychs, to be merged into the contents of screens-(dev|dev-green|prod).json
 * - `playerNameMapping`: the mapping from player name to screen ID. This should be dropped into triptych-player-(dev|dev-green|prod).json
 *
 * To change the common parts of the config objects, e.g. to make train crowding widget enabled by default or add a new PSA set, edit the body of `makeScreenConfig`.
 */

/**
 * 👉 IMPORTANT NOTES
 * ------------------
 * - Screen IDs are of the form `TRI-${StationName}-${routeID}-${directionID}-${index}`
 * - The last part, the `index`, starts at 1 for the triptych *nearest the front of the train*, and increments from there.
 *   So, if the train travels right relative to this platform, the rightmost triptych along that platform has index 1.
 *   If the train travels left, the leftmost triptych has index 1.
 * - Try to order the lists of 3 player names associated with each screen ID by left-middle-right.
 */

// vvv Add items to this array vvv

const getDraftConfigs = (): Parameters<typeof makeConfig>[] => [
  // MALDEN CENTER
  ["TRI-MaldenCenter-Orange-0-1", DirID.SB, CarDir.L, 6, "place-mlmnl", ["MAN-DS-001", "MAN-DS-002", "MAN-DS-003"], "Malden Center - OL Inbound 1"],
  ["TRI-MaldenCenter-Orange-0-2", DirID.SB, CarDir.L, 11, "place-mlmnl", ["MAN-DS-004", "MAN-DS-005", "MAN-DS-006"], "Malden Center - OL Inbound 2"],
  ["TRI-MaldenCenter-Orange-0-3", DirID.SB, CarDir.L, 16, "place-mlmnl", ["MAN-DS-007", "MAN-DS-008", "MAN-DS-009"], "Malden Center - OL Inbound 3"],

  // WELLINGTON
  ["TRI-Wellington-Orange-0-1", DirID.SB, CarDir.L, 22, "place-welln", ["WEL-DS-001", "WEL-DS-002", "WEL-DS-003"], "Wellington - OL Inbound 1"],
  ["TRI-Wellington-Orange-0-2", DirID.SB, CarDir.L, 23, "place-welln", ["WEL-DS-004", "WEL-DS-005", "WEL-DS-006"], "Wellington - OL Inbound 2"],
  ["TRI-Wellington-Orange-0-3", DirID.SB, CarDir.L, 25, "place-welln", ["WEL-DS-007", "WEL-DS-008", "WEL-DS-009"], "Wellington - OL Inbound 3"],

  // SULLIVAN SQUARE
  // 💥 The station map doesn't seem to agree with the spreadsheet for Sullivan.
  // Station map has 01-02-03::left-middle-right, spreadsheet has 01-02-03::right-middle-left
  // We should check to confirm that the player name groupings are reflected accurately, and the panes (`Array_configuration`) are tagged correctly as left/middle/right.
  // If groupings are wrong, we could end up showing the "You are here" arrow in the wrong place, or not at all.
  // If pane tags are wrong, we could end up showing left pane content on the right and vice versa.
  ["TRI-SullivanSquare-Orange-0-1", DirID.SB, CarDir.L, 9, "place-sull", ["SSQ-DS-001", "SSQ-DS-002", "SSQ-DS-003"], "Sullivan Square - OL Inbound 1"],
  ["TRI-SullivanSquare-Orange-0-2", DirID.SB, CarDir.L, 20, "place-sull", ["SSQ-DS-004", "SSQ-DS-005", "SSQ-DS-006"], "Sullivan Square - OL Inbound 2"],

  // NORTH STATION
  ["TRI-NorthStation-Orange-0-1", DirID.SB, CarDir.R, 22, "place-north", ["NST-DS-029", "NST-DS-028", "NST-DS-027"], "North Station - OL Inbound 1"],
  ["TRI-NorthStation-Orange-0-2", DirID.SB, CarDir.R, 16, "place-north", ["NST-DS-035", "NST-DS-034", "NST-DS-033"], "North Station - OL Inbound 2"],
  ["TRI-NorthStation-Orange-1-1", DirID.NB, CarDir.R, 10, "place-north", ["NST-DS-036", "NST-DS-037", "NST-DS-038"], "North Station - OL Outbound 1"],
  ["TRI-NorthStation-Orange-1-2", DirID.NB, CarDir.R, 4, "place-north", ["NST-DS-030", "NST-DS-031", "NST-DS-032"], "North Station - OL Outbound 2"],

  // HAYMARKET
  ["TRI-Haymarket-Orange-0-1", DirID.SB, CarDir.R, 16, "place-haecl", ["HAT-DS-003", "HAT-DS-002", "HAT-DS-001"], "Haymarket - OL Inbound 1"],
  ["TRI-Haymarket-Orange-0-2", DirID.SB, CarDir.R, 14, "place-haecl", ["HAT-DS-006", "HAT-DS-005", "HAT-DS-004"], "Haymarket - OL Inbound 2"],
  ["TRI-Haymarket-Orange-0-3", DirID.SB, CarDir.R, 12, "place-haecl", ["HAT-DS-009", "HAT-DS-008", "HAT-DS-007"], "Haymarket - OL Inbound 3"],
  ["TRI-Haymarket-Orange-1-1", DirID.NB, CarDir.R, 16, "place-haecl", ["HAT-DS-016", "HAT-DS-017", "HAT-DS-018"], "Haymarket - OL Outbound 1"],
  ["TRI-Haymarket-Orange-1-2", DirID.NB, CarDir.R, 14, "place-haecl", ["HAT-DS-013", "HAT-DS-014", "HAT-DS-015"], "Haymarket - OL Outbound 2"],
  ["TRI-Haymarket-Orange-1-3", DirID.NB, CarDir.R, 12, "place-haecl", ["HAT-DS-010", "HAT-DS-011", "HAT-DS-012"], "Haymarket - OL Outbound 3"],

  // STATE
  ["TRI-State-Orange-0-1", DirID.SB, CarDir.L, 10, "place-state", ["STS-DS-010", "STS-DS-011", "STS-DS-012"], "State - OL Inbound/Southbound 1"],
  ["TRI-State-Orange-0-2", DirID.SB, CarDir.L, 14, "place-state", ["STS-DS-013", "STS-DS-014", "STS-DS-015"], "State - OL Inbound/Southbound 2"],
  ["TRI-State-Orange-0-3", DirID.SB, CarDir.L, 22, "place-state", ["STS-DS-016", "STS-DS-017", "STS-DS-018"], "State - OL Inbound/Southbound 3"],
  ["TRI-State-Orange-1-1", DirID.NB, CarDir.R, 17, "place-state", ["STS-DS-007", "STS-DS-008", "STS-DS-009"], "State - OL Outbound/Northbound 1"],
  ["TRI-State-Orange-1-2", DirID.NB, CarDir.R, 10, "place-state", ["STS-DS-004", "STS-DS-005", "STS-DS-006"], "State - OL Outbound/Northbound 2"],
  ["TRI-State-Orange-1-3", DirID.NB, CarDir.R, 6, "place-state", ["STS-DS-001", "STS-DS-002", "STS-DS-003"], "State - OL Outbound/Northbound 3"],

  // DOWNTOWN CROSSING
  // NAME CHANGE: DTX / DTX
  // 💥 Travel directions seem mislabeled on the station map for this one.
  // The tracks are also not labeled with their destinations.
  // We should double-check the triptychs at DTX to make sure they're properly configured.
  ["TRI-DTX-Orange-0-1", DirID.SB, CarDir.R, 20, "place-dwnxg", ["DOW-DS-009", "DOW-DS-008", "DOW-DS-007"], "DTX - OL Outbound/Southbound 1"],
  ["TRI-DTX-Orange-0-2", DirID.SB, CarDir.R, 12, "place-dwnxg", ["DOW-DS-030", "DOW-DS-029", "DOW-DS-028"], "DTX - OL Outbound/Southbound 2"],
  ["TRI-DTX-Orange-0-3", DirID.SB, CarDir.R, 3, "place-dwnxg", ["DOW-DS-012", "DOW-DS-011", "DOW-DS-010"], "DTX - OL Outbound/Southbound 3"],
  ["TRI-DTX-Orange-1-1", DirID.NB, CarDir.R, 18, "place-dwnxg", ["DOW-DS-025", "DOW-DS-026", "DOW-DS-027"], "DTX - OL Inbound/Northbound 1"],
  ["TRI-DTX-Orange-1-2", DirID.NB, CarDir.R, 9, "place-dwnxg", ["DOW-DS-004", "DOW-DS-005", "DOW-DS-006"], "DTX - OL Inbound/Northbound 2"],
  ["TRI-DTX-Orange-1-3", DirID.NB, CarDir.R, 3, "place-dwnxg", ["DOW-DS-001", "DOW-DS-002", "DOW-DS-003"], "DTX - OL Inbound/Northbound 3"],

  // TUFTS MEDICAL CENTER
  // NAME CHANGE: TuftsMed / Tufts Med
  ["TRI-TuftsMed-Orange-0-1", DirID.SB, CarDir.R, 21, "place-tumnl", ["NMC-DS-015", "NMC-DS-014", "NMC-DS-013"], "Tufts Med - OL Outbound 1"],
  ["TRI-TuftsMed-Orange-0-2", DirID.SB, CarDir.R, 16, "place-tumnl", ["NMC-DS-009", "NMC-DS-008", "NMC-DS-007"], "Tufts Med - OL Outbound 2"],
  ["TRI-TuftsMed-Orange-0-3", DirID.SB, CarDir.R, 5, "place-tumnl", ["NMC-DS-003", "NMC-DS-002", "NMC-DS-001"], "Tufts Med - OL Outbound 3"],
  ["TRI-TuftsMed-Orange-1-1", DirID.NB, CarDir.R, 21, "place-tumnl", ["NMC-DS-004", "NMC-DS-005", "NMC-DS-006"], "Tufts Med - OL Inbound 1"],
  ["TRI-TuftsMed-Orange-1-2", DirID.NB, CarDir.R, 10, "place-tumnl", ["NMC-DS-010", "NMC-DS-011", "NMC-DS-012"], "Tufts Med - OL Inbound 2"],
  ["TRI-TuftsMed-Orange-1-3", DirID.NB, CarDir.R, 5, "place-tumnl", ["NMC-DS-016", "NMC-DS-017", "NMC-DS-018"], "Tufts Med - OL Inbound 3"],

  // BACK BAY
  ["TRI-BackBay-Orange-0-1", DirID.SB, CarDir.L, 6, "place-bbsta", ["BKB-DS-001", "BKB-DS-002", "BKB-DS-003"], "Back Bay - OL Outbound 1"],
  ["TRI-BackBay-Orange-0-2", DirID.SB, CarDir.L, 12, "place-bbsta", ["BKB-DS-004", "BKB-DS-005", "BKB-DS-006"], "Back Bay - OL Outbound 2"],
  ["TRI-BackBay-Orange-0-3", DirID.SB, CarDir.L, 18, "place-bbsta", ["BKB-DS-007", "BKB-DS-008", "BKB-DS-009"], "Back Bay - OL Outbound 3"],
  ["TRI-BackBay-Orange-1-1", DirID.NB, CarDir.L, 4, "place-bbsta", ["BKB-DS-018", "BKB-DS-017", "BKB-DS-016"], "Back Bay - OL Inbound 1"],
  ["TRI-BackBay-Orange-1-2", DirID.NB, CarDir.L, 16, "place-bbsta", ["BKB-DS-015", "BKB-DS-014", "BKB-DS-013"], "Back Bay - OL Inbound 2"],
  ["TRI-BackBay-Orange-1-3", DirID.NB, CarDir.L, 19, "place-bbsta", ["BKB-DS-012", "BKB-DS-011", "BKB-DS-010"], "Back Bay - OL Inbound 3"],

  // MASSACHUSETTS AVENUE
  // NAME CHANGE: MassAve / Mass Ave
  // 💥 One of the player names in the spreadsheet is concerning--"MAS-DS-010_failed".
  // (This is the right pane of TRI-MassAve-Orange-1-2)
  // I assumed that that name was temporary at time of the spreadsheet's creation, and used the
  // normal naming pattern without the "_failed" suffix.
  // We should check this out.
  // RELATED: Should we use player IDs instead of names? Are those less likely to change?
  //          It should be possible to get it from the MRAID object in the same way we get the player name.
  ["TRI-MassAve-Orange-0-1", DirID.SB, CarDir.L, 18, "place-masta", ["MAS-DS-007", "MAS-DS-008", "MAS-DS-009"], "Mass Ave - OL Outbound 1"],
  ["TRI-MassAve-Orange-0-2", DirID.SB, CarDir.L, 22, "place-masta", ["MAS-DS-001", "MAS-DS-002", "MAS-DS-003"], "Mass Ave - OL Outbound 2"],
  ["TRI-MassAve-Orange-1-1", DirID.NB, CarDir.L, 4, "place-masta", ["MAS-DS-006", "MAS-DS-005", "MAS-DS-004"], "Mass Ave - OL Inbound 1"],
  ["TRI-MassAve-Orange-1-2", DirID.NB, CarDir.L, 8, "place-masta", ["MAS-DS-012", "MAS-DS-011", "MAS-DS-010"], "Mass Ave - OL Inbound 2"],

  // RUGGLES
  ["TRI-Ruggles-Orange-0-1", DirID.SB, CarDir.L, 11, "place-rugg", ["RUG-DS-001", "RUG-DS-002", "RUG-DS-003"], "Ruggles - OL Outbound 1"],
  ["TRI-Ruggles-Orange-0-2", DirID.SB, CarDir.L, 20, "place-rugg", ["RUG-DS-004", "RUG-DS-005", "RUG-DS-006"], "Ruggles - OL Outbound 2"],
  ["TRI-Ruggles-Orange-1-1", DirID.NB, CarDir.L, 7, "place-rugg", ["RUG-DS-012", "RUG-DS-011", "RUG-DS-010"], "Ruggles - OL Inbound 1"],
  ["TRI-Ruggles-Orange-1-2", DirID.NB, CarDir.L, 15, "place-rugg", ["RUG-DS-009", "RUG-DS-008", "RUG-DS-007"], "Ruggles - OL Inbound 2"]
];

// ^^^ Add to this ^^^
















































// ----- You normally don't need to edit anything below here, unless changing default config shape or adding new subway lines -----

type TriptychScreenID = `TRI-${string}-Orange-${0 | 1}-${number}`;

type StationID =
  | "place-ogmnl"
  | "place-mlmnl"
  | "place-welln"
  | "place-astao"
  | "place-sull"
  | "place-ccmnl"
  | "place-north"
  | "place-haecl"
  | "place-state"
  | "place-dwnxg"
  | "place-chncl"
  | "place-tumnl"
  | "place-bbsta"
  | "place-masta"
  | "place-rugg"
  | "place-rcmnl"
  | "place-jaksn"
  | "place-sbmnl"
  | "place-grnst"
  | "place-forhl";

enum DirID {
  SB = 0,
  NB = 1,
  WB = 0,
  EB = 1
}

enum CarDir {
  L = "left",
  R = "right"
}

type PlatformPosition = number;
const isPlatformPosition = (value: number): value is PlatformPosition => {
  return value >= 1 && value <= 25;
};

interface ConfigItem {
  configEntry: [TriptychScreenID, object],
  playerNameEntries: [[string, TriptychScreenID], [string, TriptychScreenID], [string, TriptychScreenID]]
}

const getConfigs = () => JSON.stringify(mergeConfigs(getDraftConfigs().map((params) => makeConfig.apply(null, params))));

const mergeConfigs = (configs: ConfigItem[]) =>
  configs.reduce(({ screenConfig, playerNameMapping }, { configEntry: [k, v], playerNameEntries }) => ({
    screenConfig: { ...screenConfig, [k]: v },
    playerNameMapping: { ...playerNameMapping, ...Object.fromEntries(playerNameEntries) }
  }), { screenConfig: {}, playerNameMapping: {} });

const makeConfig = (id: TriptychScreenID, directionID: DirID, frontCarDirection: CarDir, platformPosition: PlatformPosition, stationID: StationID, playerNames: [string, string, string], name: string): ConfigItem => {
  if (!isPlatformPosition(platformPosition)) throw "Not a platform position";

  return {
    configEntry: [id, makeScreenConfig(directionID, frontCarDirection, platformPosition, stationID, name)],
    playerNameEntries: playerNames.map(name => [name, id]) as ConfigItem["playerNameEntries"]
  };
};

const makeScreenConfig = (directionID: DirID, frontCarDirection: CarDir, platformPosition: PlatformPosition, stationID: StationID, name: string) => ({
  "app_id": "triptych_v2",
  "app_params": {
    "evergreen_content": [],
    "local_evergreen_sets": [
      {
        "folder_name": "See-Say",
        "schedule": [
          {
            "end_dt": null,
            "start_dt": null
          }
        ]
      },
      {
        "folder_name": "Closing-Doors",
        "schedule": [
          {
            "end_dt": null,
            "start_dt": null
          }
        ]
      }
    ],
    "show_identifiers": false,
    "train_crowding": {
      "direction_id": directionID,
      "enabled": true,
      "front_car_direction": frontCarDirection,
      "platform_position": platformPosition,
      "route_id": "Orange",
      "station_id": stationID
    }
  },
  "device_id": "N/A",
  "disabled": false,
  "hidden_from_screenplay": true,
  "name": name,
  "refresh_if_loaded_before": "2023-05-09T18:41:27.318063Z",
  "tags": [],
  "vendor": "outfront"
});

// This line actually runs the thing.
console.log(getConfigs());
