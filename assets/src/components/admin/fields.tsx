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
} from "./fields/cells";

import {
  type Filter,
  BooleanFilter,
  buildSelectFilter,
  JsonFilter,
  StringFilter,
} from "./fields/filters";

type Field = {
  label: string;
  path: string;
  cell: Cell;
  filter?: Filter;
  isStatic?: boolean;
};

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

export const allFields: Field[] = [
  {
    label: "App",
    path: "app_id",
    cell: ({ value }) => SCREEN_APPS[value as AppId].name,
    isStatic: true,
  },
  ...baseFields,
  { label: "Config", path: "app_params", ...filteredJson },
];

export const appFields: { [key in AppId]: Field[] } = {
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

  busway_v2: [...baseFields, evergreenField, headerField],

  dup_v2: [
    ...baseFields,
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

  elevator_v2: [...baseFields],

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

  pre_fare_v2: [...baseFields, evergreenField, headerField],
};
