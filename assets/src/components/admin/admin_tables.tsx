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
];

const alertsColumn = {
  Header: "Alerts",
  accessor: buildAppParamAccessor("alerts"),
  mutator: buildAppParamMutator("alerts"),
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

  const dataFilter = ({ app_id }) => {
    return app_id === "gl_eink_v2";
  };

  return (
    <AdminTable
      columns={[...v2Columns, alertsColumn, lineMapColumn]}
      dataFilter={dataFilter}
    />
  );
};

const BusShelterV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "bus_shelter_v2";
  };

  return (
    <AdminTable
      columns={[...v2Columns, alertsColumn]}
      dataFilter={dataFilter}
    />
  );
};

const v2SolariColumns = [
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

const SolariV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "solari_v2";
  };

  return <AdminTable columns={v2SolariColumns} dataFilter={dataFilter} />;
};

const SolariLargeV2ScreensTable = (): JSX.Element => {
  const dataFilter = ({ app_id }) => {
    return app_id === "solari_large_v2";
  };

  return <AdminTable columns={v2SolariColumns} dataFilter={dataFilter} />;
};

export {
  AllScreensTable,
  BusScreensTable,
  GLSingleScreensTable,
  GLDoubleScreensTable,
  SolariScreensTable,
  SolariLargeScreensTable,
  DupScreensTable,
  BusEinkV2ScreensTable,
  GLEinkV2ScreensTable,
  SolariV2ScreensTable,
  SolariLargeV2ScreensTable,
  BusShelterV2ScreensTable,
};
