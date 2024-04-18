import React from "react";

import AdminTable from "Components/admin/admin_table";

import {
  filterTags,
  DefaultColumnFilter,
  SelectColumnFilter,
} from "Components/admin/admin_filters";

import {
  EditableCell,
  EditableNumberInput,
  EditableList,
  EditableSelect,
  EditableCheckbox,
  EditableTextarea,
} from "Components/admin/admin_cells";

import {
  FormTextCell,
  FormStaticCell,
  FormBoolean,
  buildFormSelect,
  FormTextarea,
} from "Components/admin/admin_form_cells";

// Helpers
const buildAppParamAccessor = (key) => {
  return (row) => row.app_params[key];
};

const buildAppParamMutator = (key) => {
  return (row, value) => ({
    ...row,
    app_params: { ...row.app_params, [key]: value },
  });
};

// Table configuration
const AllScreensTable = (): JSX.Element => {
  const columns = [
    {
      Header: "Screen ID",
      accessor: "id",
      Filter: DefaultColumnFilter,
      FormCell: FormStaticCell,
    },
    {
      Header: "Name",
      accessor: "name",
      Cell: EditableCell,
      Filter: DefaultColumnFilter,
      FormCell: FormTextCell,
    },
    {
      Header: "Vendor",
      accessor: "vendor",
      Filter: SelectColumnFilter,
      filter: "includes",
      FormCell: FormStaticCell,
    },
    {
      Header: "Device ID",
      accessor: "device_id",
      Filter: DefaultColumnFilter,
      FormCell: FormStaticCell,
    },
    {
      Header: "App ID",
      accessor: "app_id",
      Cell: EditableSelect,
      Filter: SelectColumnFilter,
      filter: "includes",
      FormCell: buildFormSelect([
        "bus_eink",
        "gl_eink_single",
        "gl_eink_double",
        "solari_eink",
      ]),
    },
    {
      Header: "Disabled",
      accessor: "disabled",
      Cell: EditableCheckbox,
      Filter: DefaultColumnFilter,
      FormCell: FormBoolean,
    },
    {
      Header: "Hidden from Screenplay",
      accessor: "hidden_from_screenplay",
      Cell: EditableCheckbox,
      Filter: DefaultColumnFilter,
      FormCell: FormBoolean,
    },
    {
      Header: "Tags",
      accessor: "tags",
      Cell: EditableList,
      Filter: DefaultColumnFilter,
      filter: filterTags,
      FormCell: FormTextCell,
    },
    {
      Header: "App Params",
      accessor: "app_params",
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  const dataFilter = () => true;
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const BusScreensTable = (): JSX.Element => {
  const columns = [
    {
      Header: "Screen ID",
      accessor: "id",
      Filter: DefaultColumnFilter,
      FormCell: FormStaticCell,
    },
    {
      Header: "Name",
      accessor: "name",
      Cell: EditableCell,
      Filter: DefaultColumnFilter,
      FormCell: FormTextCell,
    },
    {
      Header: "Stop ID",
      accessor: buildAppParamAccessor("stop_id"),
      mutator: buildAppParamMutator("stop_id"),
      Cell: EditableCell,
      Filter: DefaultColumnFilter,
      FormCell: FormTextCell,
    },
    {
      Header: "Service Level",
      accessor: buildAppParamAccessor("service_level"),
      mutator: buildAppParamMutator("service_level"),
      Cell: EditableNumberInput,
      Filter: DefaultColumnFilter,
      FormCell: buildFormSelect([1, 2, 3, 4, 5], true),
    },
    {
      Header: "Tags",
      accessor: "tags",
      Cell: EditableList,
      Filter: DefaultColumnFilter,
      filter: filterTags,
      FormCell: FormTextCell,
    },
    {
      Header: "PSA Config",
      accessor: buildAppParamAccessor("psa_config"),
      mutator: buildAppParamMutator("psa_config"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Nearby Connections",
      accessor: buildAppParamAccessor("nearby_connections"),
      mutator: buildAppParamMutator("nearby_connections"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  const dataFilter = ({ app_id }) => {
    return app_id === "bus_eink";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const greenLineAppColumns = [
  {
    Header: "Screen ID",
    accessor: "id",
    Filter: DefaultColumnFilter,
    FormCell: FormStaticCell,
  },
  {
    Header: "Name",
    accessor: "name",
    Cell: EditableCell,
    Filter: DefaultColumnFilter,
    FormCell: FormTextCell,
  },
  {
    Header: "Stop ID",
    accessor: buildAppParamAccessor("stop_id"),
    mutator: buildAppParamMutator("stop_id"),
    Cell: EditableCell,
    Filter: DefaultColumnFilter,
    FormCell: FormTextCell,
  },
  {
    Header: "Route ID",
    accessor: buildAppParamAccessor("route_id"),
    mutator: buildAppParamMutator("route_id"),
    Cell: EditableCell,
    Filter: DefaultColumnFilter,
    FormCell: FormTextCell,
  },
  {
    Header: "Direction ID",
    accessor: buildAppParamAccessor("direction_id"),
    mutator: buildAppParamMutator("direction_id"),
    Cell: EditableCell,
    Filter: DefaultColumnFilter,
    FormCell: buildFormSelect([0, 1], true),
  },
  {
    Header: "Platform ID",
    accessor: buildAppParamAccessor("platform_id"),
    mutator: buildAppParamMutator("platform_id"),
    Cell: EditableCell,
    Filter: DefaultColumnFilter,
    FormCell: FormTextCell,
  },
  {
    Header: "Headway Mode",
    accessor: buildAppParamAccessor("headway_mode"),
    mutator: buildAppParamMutator("headway_mode"),
    Cell: EditableCheckbox,
    Filter: DefaultColumnFilter,
    FormCell: FormBoolean,
  },
  {
    Header: "Service Level",
    accessor: buildAppParamAccessor("service_level"),
    mutator: buildAppParamMutator("service_level"),
    Cell: EditableNumberInput,
    Filter: DefaultColumnFilter,
    FormCell: buildFormSelect([1, 2, 3, 4, 5], true),
  },
  {
    Header: "Tags",
    accessor: "tags",
    Cell: EditableList,
    Filter: DefaultColumnFilter,
    filter: filterTags,
    FormCell: FormTextCell,
  },
  {
    Header: "PSA Config",
    accessor: buildAppParamAccessor("psa_config"),
    mutator: buildAppParamMutator("psa_config"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
  {
    Header: "Nearby Departures",
    accessor: buildAppParamAccessor("nearby_departures"),
    mutator: buildAppParamMutator("nearby_departures"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
];

const GLSingleScreensTable = (): JSX.Element => {
  const columns = greenLineAppColumns;
  const dataFilter = ({ app_id }) => {
    return app_id === "gl_eink_single";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const GLDoubleScreensTable = (): JSX.Element => {
  const columns = greenLineAppColumns;
  const dataFilter = ({ app_id }) => {
    return app_id === "gl_eink_double";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const SolariScreensTable = (): JSX.Element => {
  const columns = [
    { Header: "Screen ID", accessor: "id", Filter: DefaultColumnFilter },
    {
      Header: "Station Name",
      accessor: buildAppParamAccessor("station_name"),
      mutator: buildAppParamMutator("station_name"),
      Cell: EditableCell,
      Filter: DefaultColumnFilter,
      FormCell: FormTextCell,
    },
    {
      Header: "Overhead",
      accessor: buildAppParamAccessor("overhead"),
      mutator: buildAppParamMutator("overhead"),
      Cell: EditableCheckbox,
      Filter: DefaultColumnFilter,
      FormCell: FormBoolean,
    },
    {
      Header: "Section Headers",
      accessor: buildAppParamAccessor("section_headers"),
      mutator: buildAppParamMutator("section_headers"),
      Cell: EditableSelect,
      Filter: SelectColumnFilter,
      FormCell: buildFormSelect([null, "normal", "vertical"]),
    },
    {
      Header: "Tags",
      accessor: "tags",
      Cell: EditableList,
      Filter: DefaultColumnFilter,
      filter: filterTags,
      FormCell: FormTextCell,
    },
    {
      Header: "Sections",
      accessor: buildAppParamAccessor("sections"),
      mutator: buildAppParamMutator("sections"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Audio PSA",
      accessor: buildAppParamAccessor("audio_psa"),
      mutator: buildAppParamMutator("audio_psa"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "PSA Config",
      accessor: buildAppParamAccessor("psa_config"),
      mutator: buildAppParamMutator("psa_config"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  const dataFilter = ({ app_id }) => {
    return app_id === "solari";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const SolariLargeScreensTable = (): JSX.Element => {
  const columns = [
    { Header: "Screen ID", accessor: "id", Filter: DefaultColumnFilter },
    {
      Header: "Station Name",
      accessor: buildAppParamAccessor("station_name"),
      mutator: buildAppParamMutator("station_name"),
      Cell: EditableCell,
      Filter: DefaultColumnFilter,
      FormCell: FormTextCell,
    },
    {
      Header: "Overhead",
      accessor: buildAppParamAccessor("overhead"),
      mutator: buildAppParamMutator("overhead"),
      Cell: EditableCheckbox,
      Filter: DefaultColumnFilter,
      FormCell: FormBoolean,
    },
    {
      Header: "Section Headers",
      accessor: buildAppParamAccessor("section_headers"),
      mutator: buildAppParamMutator("section_headers"),
      Cell: EditableSelect,
      Filter: SelectColumnFilter,
      FormCell: buildFormSelect([null, "normal", "vertical"]),
    },
    {
      Header: "Tags",
      accessor: "tags",
      Cell: EditableList,
      Filter: DefaultColumnFilter,
      filter: filterTags,
      FormCell: FormTextCell,
    },
    {
      Header: "Sections",
      accessor: buildAppParamAccessor("sections"),
      mutator: buildAppParamMutator("sections"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Audio PSA",
      accessor: buildAppParamAccessor("audio_psa"),
      mutator: buildAppParamMutator("audio_psa"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "PSA Config",
      accessor: buildAppParamAccessor("psa_config"),
      mutator: buildAppParamMutator("psa_config"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  const dataFilter = ({ app_id }) => {
    return app_id === "solari_large";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const DupScreensTable = (): JSX.Element => {
  const columns = [
    { Header: "Screen ID", accessor: "id", Filter: DefaultColumnFilter },
    {
      Header: "Primary Departures",
      accessor: buildAppParamAccessor("primary"),
      mutator: buildAppParamMutator("primary"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Secondary Departures",
      accessor: buildAppParamAccessor("secondary"),
      mutator: buildAppParamMutator("secondary"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Override",
      accessor: buildAppParamAccessor("override"),
      mutator: buildAppParamMutator("override"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  const dataFilter = ({ app_id }) => {
    return app_id === "dup";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const DupV2ScreensTable = (): JSX.Element => {
  const columns = [
    { Header: "Screen ID", accessor: "id", Filter: DefaultColumnFilter },
    {
      Header: "Header",
      accessor: buildAppParamAccessor("header"),
      mutator: buildAppParamMutator("header"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Primary Departures",
      accessor: buildAppParamAccessor("primary_departures"),
      mutator: buildAppParamMutator("primary_departures"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Secondary Departures",
      accessor: buildAppParamAccessor("secondary_departures"),
      mutator: buildAppParamMutator("secondary_departures"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Alerts",
      accessor: buildAppParamAccessor("alerts"),
      mutator: buildAppParamMutator("alerts"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Evergreen Content",
      accessor: buildAppParamAccessor("evergreen_content"),
      mutator: buildAppParamMutator("evergreen_content"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  const dataFilter = ({ app_id }) => {
    return app_id === "dup_v2";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const v2Columns = [
  {
    Header: "Screen ID",
    accessor: "id",
    Filter: DefaultColumnFilter,
    FormCell: FormStaticCell,
  },
  {
    Header: "Name",
    accessor: "name",
    Cell: EditableCell,
    Filter: DefaultColumnFilter,
    FormCell: FormTextCell,
  },
  {
    Header: "Departures",
    accessor: buildAppParamAccessor("departures"),
    mutator: buildAppParamMutator("departures"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
  {
    Header: "Footer",
    accessor: buildAppParamAccessor("footer"),
    mutator: buildAppParamMutator("footer"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
  {
    Header: "Header",
    accessor: buildAppParamAccessor("header"),
    mutator: buildAppParamMutator("header"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
  {
    Header: "Evergreen Content",
    accessor: buildAppParamAccessor("evergreen_content"),
    mutator: buildAppParamMutator("evergreen_content"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
];

const screenIDColumn = {
  Header: "Screen ID",
  accessor: "id",
  Filter: DefaultColumnFilter,
  FormCell: FormStaticCell,
};

const screenNameColumn = {
  Header: "Name",
  accessor: "name",
  Cell: EditableCell,
  Filter: DefaultColumnFilter,
  FormCell: FormTextCell,
};

const evergreenContentColumn = {
  Header: "Evergreen Content",
  accessor: buildAppParamAccessor("evergreen_content"),
  mutator: buildAppParamMutator("evergreen_content"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const alertsColumn = {
  Header: "Alerts",
  accessor: buildAppParamAccessor("alerts"),
  mutator: buildAppParamMutator("alerts"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const surveyColumn = {
  Header: "Survey",
  accessor: buildAppParamAccessor("survey"),
  mutator: buildAppParamMutator("survey"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const BusEinkV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "bus_eink_v2";
  };

  return (
    <AdminTable
      columns={[...v2Columns, alertsColumn]}
      dataFilter={dataFilter}
    />
  );
};

const GLEinkV2ScreensTable = (): JSX.Element => {
  const lineMapColumn = {
    Header: "Line Map",
    accessor: buildAppParamAccessor("line_map"),
    mutator: buildAppParamMutator("line_map"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  };

  const platformLocationColumn = {
    Header: "Platform Location",
    accessor: buildAppParamAccessor("platform_location"),
    mutator: buildAppParamMutator("platform_location"),
    Cell: EditableSelect,
    disableFilters: true,
    FormCell: buildFormSelect(["front", "back"], false),
  };

  const dataFilter = ({ app_id }) => {
    return app_id === "gl_eink_v2";
  };

  return (
    <AdminTable
      columns={[
        ...v2Columns,
        alertsColumn,
        lineMapColumn,
        audioColumn,
        platformLocationColumn,
      ]}
      dataFilter={dataFilter}
    />
  );
};

const audioColumn = {
  Header: "Audio",
  accessor: buildAppParamAccessor("audio"),
  mutator: buildAppParamMutator("audio"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const BusShelterV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "bus_shelter_v2";
  };

  return (
    <AdminTable
      columns={[...v2Columns, alertsColumn, surveyColumn, audioColumn]}
      dataFilter={dataFilter}
    />
  );
};

const elevatorStatusColumn = {
  Header: "Elevator Status",
  accessor: buildAppParamAccessor("elevator_status"),
  mutator: buildAppParamMutator("elevator_status"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const reconstructedAlertWidgetColumn = {
  Header: "Alert Widget",
  accessor: buildAppParamAccessor("reconstructed_alert_widget"),
  mutator: buildAppParamMutator("reconstructed_alert_widget"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const lineMapColumn = {
  Header: "Full Line Map",
  accessor: buildAppParamAccessor("full_line_map"),
  mutator: buildAppParamMutator("full_line_map"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const contentSummaryColumn = {
  Header: "Content Summary",
  accessor: buildAppParamAccessor("content_summary"),
  mutator: buildAppParamMutator("content_summary"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const crDeparturesColumn = {
  Header: "Commuter Rail",
  accessor: buildAppParamAccessor("cr_departures"),
  mutator: buildAppParamMutator("cr_departures"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const blueBikesColumn = {
  Header: "BlueBikes",
  accessor: buildAppParamAccessor("blue_bikes"),
  mutator: buildAppParamMutator("blue_bikes"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const shuttleBusInfoColumn = {
  Header: "Shuttle Bus Info",
  accessor: buildAppParamAccessor("shuttle_bus_info"),
  mutator: buildAppParamMutator("shuttle_bus_info"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const trainCrowdingColumn = {
  Header: "Train Crowding",
  accessor: buildAppParamAccessor("train_crowding"),
  mutator: buildAppParamMutator("train_crowding"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const localEvergreenSetsColumn = {
  Header: "Local Evergreen Content Sets",
  accessor: buildAppParamAccessor("local_evergreen_sets"),
  mutator: buildAppParamMutator("local_evergreen_sets"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const showIdentifiersColumn = {
  Header: "Show Version & Player Name?",
  accessor: buildAppParamAccessor("show_identifiers"),
  mutator: buildAppParamMutator("show_identifiers"),
  Cell: EditableCheckbox,
  Filter: DefaultColumnFilter,
  FormCell: FormBoolean,
}

const PreFareV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "pre_fare_v2";
  };

  return (
    <AdminTable
      columns={[
        ...v2Columns,
        lineMapColumn,
        elevatorStatusColumn,
        reconstructedAlertWidgetColumn,
        contentSummaryColumn,
        crDeparturesColumn,
        blueBikesColumn,
        shuttleBusInfoColumn,
        audioColumn
      ]}
      dataFilter={dataFilter}
    />
  );
};

const v2BuswayColumns = [
  {
    Header: "Screen ID",
    accessor: "id",
    Filter: DefaultColumnFilter,
    FormCell: FormStaticCell,
  },
  {
    Header: "Name",
    accessor: "name",
    Cell: EditableCell,
    Filter: DefaultColumnFilter,
    FormCell: FormTextCell,
  },
  {
    Header: "Departures",
    accessor: buildAppParamAccessor("departures"),
    mutator: buildAppParamMutator("departures"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
  {
    Header: "Header",
    accessor: buildAppParamAccessor("header"),
    mutator: buildAppParamMutator("header"),
    Cell: EditableTextarea,
    disableFilters: true,
    FormCell: FormTextarea,
  },
];

const BuswayV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "busway_v2";
  };

  return <AdminTable columns={v2BuswayColumns} dataFilter={dataFilter} />;
};

const SolariLargeV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "solari_large_v2";
  };

  return <AdminTable columns={v2BuswayColumns} dataFilter={dataFilter} />;
};

const TriptychV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "triptych_v2";
  };

  return (
    <AdminTable
      columns={[
        screenIDColumn,
        screenNameColumn,
        trainCrowdingColumn,
        localEvergreenSetsColumn,
        evergreenContentColumn,
        showIdentifiersColumn
      ]}
      dataFilter={dataFilter}
    />
  );
};

export {
  AllScreensTable,
  BusScreensTable,
  GLSingleScreensTable,
  GLDoubleScreensTable,
  SolariScreensTable,
  SolariLargeScreensTable,
  DupScreensTable,
  DupV2ScreensTable,
  BusEinkV2ScreensTable,
  GLEinkV2ScreensTable,
  BuswayV2ScreensTable,
  SolariLargeV2ScreensTable,
  BusShelterV2ScreensTable,
  PreFareV2ScreensTable,
  TriptychV2ScreensTable,
};
