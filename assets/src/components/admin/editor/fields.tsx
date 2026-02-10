import { type AppId, SCREEN_APPS, SCREEN_VENDORS } from "Util/admin";

import {
  type Cell,
  buildSelectInput,
  CheckboxInput,
  InspectorLink,
  JsonInput,
  NullStringInput,
  NumberInput,
  StringInput,
} from "./cells";

import {
  type Filter,
  BooleanFilter,
  buildSelectFilter,
  JsonFilter,
  StringFilter,
} from "./filters";

/**
 * Represents a screen configuration field that can be viewed or edited.
 *
 * - `label` is a user-facing name for the field
 * - `path` is the dot-separated "property path" to the field within a screen's
 *   configuration (as understood by e.g. `_.get`)
 * - `cell` is a component that renders the value of the field for a specific
 *   screen, and may allow editing it
 * - `filter` is a component that allows filtering on the value of the field
 *   across all screens
 * - `isStatic` indicates this value cannot be changed after screen creation
 */
type Field = {
  label?: string;
  path: string;
  cell: Cell;
  filter?: Filter;
  isStatic?: boolean;
};

// Helper "mix-ins" for common combinations of `cell` and `filter`.
const filteredBoolean = { cell: CheckboxInput, filter: BooleanFilter };
const filteredJson = { cell: JsonInput, filter: JsonFilter };
const filteredNullString = { cell: NullStringInput, filter: StringFilter };
const filteredString = { cell: StringInput, filter: StringFilter };

const baseFields: Field[] = [
  {
    label: "ID",
    path: "id",
    cell: InspectorLink,
    filter: StringFilter,
    isStatic: true,
  },
  { label: "Name", path: "name", ...filteredString },
  { label: "Location", path: "location", ...filteredString },
  {
    label: "Vendor",
    path: "vendor",
    cell: buildSelectInput([null, ...SCREEN_VENDORS]),
    filter: buildSelectFilter(SCREEN_VENDORS),
  },
  { label: "Device ID", path: "device_id", ...filteredString },
  { label: "Disabled?", path: "disabled", ...filteredBoolean },
  { label: "Hidden?", path: "hidden_from_screenplay", ...filteredBoolean },
];

const alertsField: Field = {
  label: "Alerts Stop ID",
  path: "app_params.alerts.stop_id",
  ...filteredString,
};

const departuresField: Field = {
  label: "Departures Sections",
  path: "app_params.departures.sections",
  ...filteredJson,
};

const evergreenField: Field = {
  label: "Evergreen Content",
  path: "app_params.evergreen_content",
  ...filteredJson,
};

const footerField: Field = {
  label: "Footer Stop ID",
  path: "app_params.footer.stop_id",
  ...filteredNullString,
};

const headerField: Field = {
  label: "Header",
  path: "app_params.header",
  ...filteredJson,
};

/**
 * The fields used when editing "all" screens (across multiple App IDs).
 */
export const ALL_FIELDS: Field[] = [
  {
    path: "app_id",
    cell: ({ value }) => SCREEN_APPS[value as AppId].name,
    isStatic: true,
  },
  ...baseFields,
  { label: "Config", path: "app_params", ...filteredJson },
];

/**
 * The fields used when editing screens of a specific App ID.
 */
export const APP_FIELDS: { [key in AppId]: Field[] } = {
  bus_eink_v2: [
    ...baseFields,
    evergreenField,
    headerField,
    departuresField,
    {
      label: "Alerts Stop IDs",
      path: "app_params.alerts.stop_ids",
      ...filteredJson,
    },
    footerField,
  ],

  bus_shelter_v2: [
    ...baseFields,
    {
      label: "🔈Interval?",
      path: "app_params.audio.interval_enabled",
      ...filteredBoolean,
    },
    {
      label: "🔈Offset",
      path: "app_params.audio.interval_offset_seconds",
      cell: NumberInput,
    },
    evergreenField,
    headerField,
    departuresField,
    alertsField,
    {
      label: "Survey",
      path: "app_params.survey",
      ...filteredJson,
    },
  ],

  busway_v2: [
    ...baseFields,
    evergreenField,
    {
      label: "Logo?",
      path: "app_params.include_logo_in_header",
      ...filteredBoolean,
    },
    headerField,
    departuresField,
  ],

  dup_v2: [
    ...baseFields,
    evergreenField,
    headerField,
    alertsField,
    {
      label: "Primary Departures",
      path: "app_params.primary_departures",
      ...filteredJson,
    },
    {
      label: "Secondary Departures",
      path: "app_params.secondary_departures",
      ...filteredJson,
    },
  ],

  gl_eink_v2: [
    ...baseFields,
    {
      label: "Placement",
      path: "app_params.platform_location",
      cell: buildSelectInput([null, "front", "back"]),
      filter: buildSelectFilter(["front", "back"]),
    },
    evergreenField,
    headerField,
    {
      label: "Line Map",
      path: "app_params.line_map",
      ...filteredJson,
    },
    departuresField,
    alertsField,
    footerField,
  ],

  pre_fare_v2: [
    ...baseFields,
    {
      label: "Template",
      path: "app_params.template",
      cell: buildSelectInput(["duo", "solo"]),
      filter: buildSelectFilter(["duo", "solo"]),
    },
    evergreenField,
    headerField,
    departuresField,
    { label: "Line Map", path: "app_params.full_line_map", ...filteredJson },
    {
      label: "Content Summary Station ID",
      path: "app_params.content_summary.parent_station_id",
      ...filteredString,
    },
    {
      ...alertsField,
      path: "app_params.reconstructed_alert_widget.stop_id",
    },
    {
      label: "Elevator Status Station ID",
      path: "app_params.elevator_status.parent_station_id",
      ...filteredString,
    },
  ],
};
