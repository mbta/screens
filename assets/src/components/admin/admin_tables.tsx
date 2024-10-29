import React from "react";

import AdminTable from "Components/admin/admin_table";

import {
  filterTags,
  DefaultColumnFilter,
  SelectColumnFilter,
} from "Components/admin/admin_filters";

import {
  EditableCell,
  EditableList,
  EditableSelect,
  EditableCheckbox,
  EditableTextarea,
  InspectorLink,
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
      Cell: InspectorLink,
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
      FormCell: FormStaticCell,
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

const SolariScreensTable = (): JSX.Element => {
  const columns = [
    {
      Header: "Screen ID",
      accessor: "id",
      Cell: InspectorLink,
      Filter: DefaultColumnFilter,
    },
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

const v2Columns = [
  {
    Header: "Screen ID",
    accessor: "id",
    Cell: InspectorLink,
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

const departuresColumn = {
  Header: "Departures",
  accessor: buildAppParamAccessor("departures"),
  mutator: buildAppParamMutator("departures"),
  Cell: EditableTextarea,
  disableFilters: true,
  FormCell: FormTextarea,
};

const footerColumn = {
  Header: "Footer",
  accessor: buildAppParamAccessor("footer"),
  mutator: buildAppParamMutator("footer"),
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

const DupV2ScreensTable = (): JSX.Element => {
  const columns = [
    ...v2Columns,
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
    alertsColumn,
  ];

  const dataFilter = ({ app_id }) => {
    return app_id === "dup_v2";
  };
  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const BusEinkV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "bus_eink_v2";
  };

  const columns = [...v2Columns, departuresColumn, footerColumn, alertsColumn];

  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const GLEinkV2ScreensTable = (): JSX.Element => {
  const columns = [
    ...v2Columns,
    {
      Header: "Line Map",
      accessor: buildAppParamAccessor("line_map"),
      mutator: buildAppParamMutator("line_map"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Platform Location",
      accessor: buildAppParamAccessor("platform_location"),
      mutator: buildAppParamMutator("platform_location"),
      Cell: EditableSelect,
      disableFilters: true,
      FormCell: buildFormSelect(["front", "back"], false),
    },
    departuresColumn,
    footerColumn,
    alertsColumn,
  ];

  const dataFilter = ({ app_id }) => {
    return app_id === "gl_eink_v2";
  };

  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const BusShelterV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "bus_shelter_v2";
  };

  const columns = [
    ...v2Columns,
    {
      Header: "Audio Offset",
      accessor: (row) => row.app_params.audio.interval_offset_seconds,
      mutator: (row, value) => {
        const newRow = structuredClone(row);
        newRow.app_params.audio.interval_offset_seconds = value;
        return newRow;
      },
      Cell: EditableCell,
      disableFilters: true,
      FormCell: FormTextCell,
    },
    departuresColumn,
    footerColumn,
    alertsColumn,
    {
      Header: "Survey",
      accessor: buildAppParamAccessor("survey"),
      mutator: buildAppParamMutator("survey"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const PreFareV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "pre_fare_v2";
  };

  const columns = [
    ...v2Columns,
    {
      Header: "Elevator Status",
      accessor: buildAppParamAccessor("elevator_status"),
      mutator: buildAppParamMutator("elevator_status"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Alert Widget",
      accessor: buildAppParamAccessor("reconstructed_alert_widget"),
      mutator: buildAppParamMutator("reconstructed_alert_widget"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Full Line Map",
      accessor: buildAppParamAccessor("full_line_map"),
      mutator: buildAppParamMutator("full_line_map"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Content Summary",
      accessor: buildAppParamAccessor("content_summary"),
      mutator: buildAppParamMutator("content_summary"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Commuter Rail",
      accessor: buildAppParamAccessor("cr_departures"),
      mutator: buildAppParamMutator("cr_departures"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "BlueBikes",
      accessor: buildAppParamAccessor("blue_bikes"),
      mutator: buildAppParamMutator("blue_bikes"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
    {
      Header: "Shuttle Bus Info",
      accessor: buildAppParamAccessor("shuttle_bus_info"),
      mutator: buildAppParamMutator("shuttle_bus_info"),
      Cell: EditableTextarea,
      disableFilters: true,
      FormCell: FormTextarea,
    },
  ];

  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

const elevatorIdColumn = {
  Header: "Elevator ID",
  accessor: buildAppParamAccessor("elevator_id"),
  mutator: buildAppParamMutator("elevator_id"),
  Cell: EditableCell,
  disableFilters: true,
  FormCell: FormTextCell,
};

const ElevatorV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "elevator_v2";
  };

  return (
    <AdminTable
      columns={[
        {
          Header: "Screen ID",
          accessor: "id",
          Cell: InspectorLink,
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
          Header: "Evergreen Content",
          accessor: buildAppParamAccessor("evergreen_content"),
          mutator: buildAppParamMutator("evergreen_content"),
          Cell: EditableTextarea,
          disableFilters: true,
          FormCell: FormTextarea,
        },
        elevatorIdColumn,
      ]}
      dataFilter={dataFilter}
    />
  );
};

const BuswayV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "busway_v2";
  };

  const columns = [...v2Columns, departuresColumn];

  return <AdminTable columns={columns} dataFilter={dataFilter} />;
};

export {
  AllScreensTable,
  BusEinkV2ScreensTable,
  BusShelterV2ScreensTable,
  BuswayV2ScreensTable,
  DupV2ScreensTable,
  ElevatorV2ScreensTable,
  GLEinkV2ScreensTable,
  PreFareV2ScreensTable,
  SolariScreensTable,
};
