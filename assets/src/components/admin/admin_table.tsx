import React, { useState, useEffect } from "react";
import { useTable, useFilters, useRowSelect } from "react-table";
import _ from "lodash";
import weakKey from "weak-key";

import { doSubmit } from "Util/admin";
import { IndeterminateCheckbox } from "Components/admin/admin_cells";
import AddModal from "Components/admin/admin_add_modal";
import EditModal from "Components/admin/admin_edit_modal";

const VALIDATE_PATH = "/api/admin/screens/validate";
const CONFIRM_PATH = "/api/admin/screens/confirm";
const REFRESH_PATH = "/api/admin/refresh";

// Helpers
const buildDefaultMutator = (columnId) => {
  return (row, value) => {
    return { ...row, [columnId]: value };
  };
};

const buildIndexMapping = (data, dataFilter) => {
  // Map from index in filter to index in all data
  const [indexMapping] = data.reduce(
    ([acc, filteredIndex], row, index) => {
      const isIncluded = dataFilter(row);
      return [
        isIncluded ? { ...acc, [filteredIndex]: index } : acc,
        isIncluded ? filteredIndex + 1 : filteredIndex,
      ];
    },
    [{}, 0],
  );

  return indexMapping;
};

// Renders the table
const Table = ({
  columns,
  data,
  unfilteredData,
  setData,
  doUpdate,
  onValidate,
  editable,
  setEditable,
  setTableVersion,
}): JSX.Element => {
  const {
    getTableProps,
    getTableBodyProps,
    headerGroups,
    rows,
    prepareRow,
    state: { selectedRowIds },
  } = useTable(
    {
      columns,
      data,
      doUpdate,
      editable,
    },
    useFilters,
    useRowSelect,
    (hooks) => {
      hooks.visibleColumns.push((cols) => [
        {
          id: "selection",
          Header: ({ getToggleAllRowsSelectedProps }) => (
            <div>
              <IndeterminateCheckbox {...getToggleAllRowsSelectedProps()} />
            </div>
          ),
          Cell: ({ row }) => (
            <div>
              <IndeterminateCheckbox {...row.getToggleRowSelectedProps()} />
            </div>
          ),
        },
        ...cols,
      ]);
    },
  );

  return (
    <>
      <table {...getTableProps()}>
        <thead>
          {headerGroups.map((headerGroup) => (
            <tr
              key={weakKey(headerGroup)}
              {...headerGroup.getHeaderGroupProps()}
            >
              {headerGroup.headers.map((column) => (
                <th key={column.id} {...column.getHeaderProps()}>
                  {column.render("Header")}
                  <div>{column.canFilter ? column.render("Filter") : null}</div>
                </th>
              ))}
            </tr>
          ))}
        </thead>

        <tbody {...getTableBodyProps()}>
          {rows.map((row) => {
            prepareRow(row);
            return (
              <tr key={weakKey(row)} {...row.getRowProps()}>
                {row.cells.map((cell) => {
                  return (
                    <td key={cell.column.id} {...cell.getCellProps()}>
                      {cell.render("Cell")}
                    </td>
                  );
                })}
              </tr>
            );
          })}
        </tbody>
      </table>
      <AdminTableControls
        columns={columns}
        data={data}
        unfilteredData={unfilteredData}
        setData={setData}
        editable={editable}
        setEditable={setEditable}
        onValidate={onValidate}
        selectedRowIds={selectedRowIds}
        doUpdate={doUpdate}
        setTableVersion={setTableVersion}
      />
    </>
  );
};

// Helpers to convert between screen table data and config object
const configToData = (config) => {
  return _.chain(config.screens)
    .toPairs()
    .map(([screenId, screenData]) => ({ ...screenData, id: screenId }))
    .sortBy((screenData) => screenData.id)
    .value();
};

const dataToConfig = (data) => {
  const screens = _.chain(data)
    .map(({ id, ...screenConfig }) => [id, screenConfig])
    .fromPairs()
    .value();

  return { screens };
};

// Functions to make API calls
const doValidate = async (data, onValidate) => {
  const config = dataToConfig(data);
  const dataToSubmit = { config: JSON.stringify(config, null, 2) };
  const result = await doSubmit(VALIDATE_PATH, dataToSubmit);
  const validatedConfig = await configToData(result.config);
  onValidate(validatedConfig);
};

const doConfirm = async (data, setEditable) => {
  const config = dataToConfig(data);
  const dataToSubmit = { config: JSON.stringify(config, null, 2) };
  const result = await doSubmit(CONFIRM_PATH, dataToSubmit);
  if (result.success === true) {
    alert("Config updated successfully");
    window.location.reload();
  } else {
    alert("Config update failed");
    setEditable(true);
  }
};

const doRefresh = async (data, selectedRowIds) => {
  const msg =
    "Are you sure? Any unconfirmed changes to the config will be lost.";
  if (confirm(msg)) {
    const selectedRows = _.filter(data, (_row, i) => selectedRowIds[i]);
    const selectedScreenIds = _.map(selectedRows, ({ id }) => id);
    const dataToSubmit = { screen_ids: selectedScreenIds };
    const result = await doSubmit(REFRESH_PATH, dataToSubmit);
    if (result.success === true) {
      alert("Refresh scheduled successfully");
      window.location.reload();
    } else {
      alert("Refresh schedule failed");
    }
  }
};

const AdminTableControls = ({
  columns,
  data,
  unfilteredData,
  setData,
  editable,
  setEditable,
  onValidate,
  selectedRowIds,
  doUpdate,
  setTableVersion,
}): JSX.Element => {
  const [showEditModal, setShowEditModal] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  let controlsDiv;

  const disableMultiEdit = Object.keys(selectedRowIds).length === 0;

  if (editable) {
    controlsDiv = (
      <div className="admin-table__controls">
        <button onClick={() => setShowAddModal(true)}>Add New Screen</button>
        <button
          disabled={disableMultiEdit}
          onClick={() => setShowEditModal(true)}
        >
          Edit Selected Rows
        </button>
        <button
          disabled={disableMultiEdit}
          onClick={() => doRefresh(data, selectedRowIds)}
        >
          Refresh Selected Rows
        </button>
        <button onClick={() => doValidate(unfilteredData, onValidate)}>
          Validate
        </button>
      </div>
    );
  } else {
    controlsDiv = (
      <div className="admin-table__controls">
        <button onClick={() => setEditable(true)}>Back</button>
        <button onClick={() => doConfirm(unfilteredData, setEditable)}>
          Confirm
        </button>
      </div>
    );
  }

  return (
    <div>
      {controlsDiv}
      {showEditModal ? (
        <EditModal
          columns={columns}
          data={data}
          selectedRowIds={selectedRowIds}
          setShowEditModal={setShowEditModal}
          setTableVersion={setTableVersion}
          doUpdate={doUpdate}
        />
      ) : null}
      {showAddModal ? (
        <AddModal setData={setData} closeModal={() => setShowAddModal(false)} />
      ) : null}
    </div>
  );
};

const AdminTable = ({ columns, dataFilter }): JSX.Element => {
  const [data, setData] = useState<any[]>([]);
  const [editable, setEditable] = useState(true);
  const [tableVersion, setTableVersion] = useState(0);

  // Fetch config on page load
  const fetchConfig = async () => {
    const result = await fetch("/api/admin/");
    const json = await result.json();
    const config = JSON.parse(json.config);
    setData(configToData(config));
  };

  useEffect(() => {
    fetchConfig();
    return;
  }, []);

  const onValidate = (validatedConfig) => {
    setData(validatedConfig);
    setEditable(false);
    setTableVersion((version) => version + 1);
  };

  // Update the state when the user makes changes in the table
  const indexMapping = buildIndexMapping(data, dataFilter);
  const doUpdate = (rowIndex, columnIdOrMutator, value) => {
    const mutator =
      typeof columnIdOrMutator === "function"
        ? columnIdOrMutator
        : buildDefaultMutator(columnIdOrMutator);

    const origIndex = indexMapping[rowIndex];
    setData((orig) =>
      orig.map((row, index) => {
        if (index === origIndex) {
          return mutator(row, value);
        }
        return row;
      }),
    );
  };

  return (
    <div className="admin-table">
      {data.length > 0 ? (
        <>
          <Table
            columns={columns}
            data={data.filter(dataFilter)}
            unfilteredData={data}
            setData={setData}
            doUpdate={doUpdate}
            editable={editable}
            setEditable={setEditable}
            onValidate={onValidate}
            setTableVersion={setTableVersion}
            key={`table-${tableVersion}`}
          />
        </>
      ) : (
        <div>Loading data...</div>
      )}
    </div>
  );
};

export default AdminTable;
