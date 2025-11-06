import { type AppId, SCREEN_APPS, SCREEN_VENDORS } from "Util/admin";

import {
  type Cell,
  buildSelectInput,
  CheckboxInput,
  InspectorLink,
  JsonInput,
  StringInput,
} from "./fields/cells";

import {
  type Filter,
  BooleanFilter,
  buildSelectFilter,
  StringFilter,
} from "./fields/filters";

type Field = {
  label: string;
  path: string;
  cell: Cell;
  filter?: Filter;
};

const filteredBoolean = { cell: CheckboxInput, filter: BooleanFilter };
const filteredString = { cell: StringInput, filter: StringFilter };

const baseFields: Field[] = [
  { label: "ID", path: "id", cell: InspectorLink, filter: StringFilter },
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

export const allFields: Field[] = [
  {
    label: "App",
    path: "app_id",
    cell: ({ value }) => SCREEN_APPS[value as AppId].name,
  },
  ...baseFields,
  { label: "Config", path: "app_params", cell: JsonInput },
];

export const appFields: { [key in AppId]: Field[] } = {
  bus_eink_v2: [...baseFields],
  bus_shelter_v2: [...baseFields],
  busway_v2: [...baseFields],
  dup_v2: [...baseFields],
  elevator_v2: [...baseFields],
  gl_eink_v2: [...baseFields],
  pre_fare_v2: [...baseFields],
};
