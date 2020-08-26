import React, { useState, useEffect, useMemo, useRef } from "react";
import { useTable, useFilters } from "react-table";
import _ from "lodash";

import { doSubmit } from "Util/admin";

const VALIDATE_PATH = "/api/admin/validate";
const CONFIRM_PATH = "/api/admin/confirm";

// Helpers
const gatherSelectOptions = (rows, columnId) => {
  const options = rows.map((row) => row.values[columnId]);
  const uniqueOptions = new Set(options);
  return Array.from(uniqueOptions);
};

// Filters
const DefaultColumnFilter = ({
  column: { filterValue, preFilteredRows, setFilter },
}) => {
  const count = preFilteredRows.length;

  return (
    <input
      value={filterValue || ""}
      onChange={(e) => {
        setFilter(e.target.value || undefined);
      }}
      placeholder={`Search ${count} records...`}
    />
  );
};

const SelectColumnFilter = ({
  column: { filterValue, setFilter, preFilteredRows, id },
}) => {
  const options = useMemo(() => gatherSelectOptions(preFilteredRows, id), [
    id,
    preFilteredRows,
  ]);

  return (
    <select
      value={filterValue}
      onChange={(e) => {
        setFilter(e.target.value || undefined);
      }}
    >
      <option value="">All</option>
      {options.map((option, i) => (
        <option key={i} value={option}>
          {option}
        </option>
      ))}
    </select>
  );
};

// Cell Components
const EditableCell = ({
  value: initialValue,
  row: { index },
  column: { id },
  doUpdate,
  editable,
}) => {
  const inputElt = useRef(null);

  const onBlur = () => {
    if (inputElt.current) {
      doUpdate(index, id, inputElt.current.value);
    }
  };

  return (
    <input
      defaultValue={initialValue}
      ref={inputElt}
      className={`admin-table__column--${id}`}
      onBlur={onBlur}
      disabled={!editable}
    />
  );
};

const EditableSelect = ({
  value: initialValue,
  row: { index },
  column: { id, preFilteredRows },
  doUpdate,
  editable,
}) => {
  const options = useMemo(() => gatherSelectOptions(preFilteredRows, id), [
    id,
    preFilteredRows,
  ]);

  const selectElt = useRef(null);

  const onChange = (e) => {
    if (selectElt.current) {
      doUpdate(index, id, selectElt.current.value);
    }
  };

  return (
    <select
      defaultValue={initialValue}
      ref={selectElt}
      onChange={onChange}
      disabled={!editable}
    >
      {options.map((opt) => (
        <option value={opt} key={opt}>
          {opt}
        </option>
      ))}
    </select>
  );
};

const EditableCheckbox = ({
  value: initialValue,
  row: { index },
  column: { id },
  doUpdate,
  editable,
}) => {
  const inputElt = useRef(null);

  const onChange = (e) => {
    if (inputElt.current) {
      doUpdate(index, id, inputElt.current.checked);
    }
  };

  return (
    <input
      ref={inputElt}
      type="checkbox"
      defaultChecked={initialValue}
      onChange={onChange}
      disabled={!editable}
    />
  );
};

const EditableTextarea = ({
  value: initialValue,
  row: { index, values: rowValues },
  column: { id },
  doUpdate,
  editable,
}) => {
  const textareaElt = useRef(null);

  const onBlur = () => {
    if (textareaElt.current) {
      try {
        const json = JSON.parse(textareaElt.current.value);
        doUpdate(index, id, json);
      } catch (err) {
        alert(`Invalid JSON in ${id} for Screen ID ${rowValues.id}`);
      }
    }
  };

  return (
    <textarea
      ref={textareaElt}
      className="admin-table__textarea"
      defaultValue={JSON.stringify(initialValue, null, 2)}
      onBlur={onBlur}
      disabled={!editable}
    />
  );
};

// Renders the table
const Table = ({ columns, data, doUpdate, editable }): JSX.Element => {
  const {
    getTableProps,
    getTableBodyProps,
    headerGroups,
    rows,
    prepareRow,
    state,
    visibleColumns,
    preGlobalFilteredRows,
    setGlobalFilter,
  } = useTable(
    {
      columns,
      data,
      doUpdate,
      editable,
    },
    useFilters
  );

  return (
    <table {...getTableProps()}>
      <thead>
        {headerGroups.map((headerGroup) => (
          <tr {...headerGroup.getHeaderGroupProps()}>
            {headerGroup.headers.map((column) => (
              <th {...column.getHeaderProps()}>
                {column.render("Header")}
                <div>{column.canFilter ? column.render("Filter") : null}</div>
              </th>
            ))}
          </tr>
        ))}
      </thead>

      <tbody {...getTableBodyProps()}>
        {rows.map((row, i) => {
          prepareRow(row);
          return (
            <tr {...row.getRowProps()}>
              {row.cells.map((cell) => {
                return <td {...cell.getCellProps()}>{cell.render("Cell")}</td>;
              })}
            </tr>
          );
        })}
      </tbody>
    </table>
  );
};

// Helpers to convert between screen table data and config object
const configToData = (config) => {
  return _.chain(config.screens)
    .toPairs()
    .map(([screenId, screenData]) => ({ ...screenData, id: screenId }))
    .sortBy((screenData) => parseInt(screenData.id, 10))
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
const doValidate = async (data, setData, setEditable) => {
  const config = dataToConfig(data);
  const dataToSubmit = { config: JSON.stringify(config, null, 2) };
  const result = await doSubmit(VALIDATE_PATH, dataToSubmit);
  const validatedConfig = await configToData(result.config);
  setData(validatedConfig);
  setEditable(false);
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

const AdminTableControls = ({
  data,
  setData,
  editable,
  setEditable,
}): JSX.Element => {
  if (editable) {
    return (
      <div className="admin-table__controls">
        <button onClick={() => doValidate(data, setData, setEditable)}>
          Validate
        </button>
      </div>
    );
  } else {
    return (
      <div className="admin-table__controls">
        <button onClick={() => setEditable(true)}>Back</button>
        <button onClick={() => doConfirm(data, setEditable)}>Confirm</button>
      </div>
    );
  }
};

const AdminTable = (): JSX.Element => {
  const [data, setData] = useState([]);
  const [editable, setEditable] = useState(true);

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

  const columns = [
    { Header: "Screen ID", accessor: "id", Filter: DefaultColumnFilter },
    {
      Header: "Name",
      accessor: "name",
      Cell: EditableCell,
      Filter: DefaultColumnFilter,
    },
    {
      Header: "Vendor",
      accessor: "vendor",
      Filter: SelectColumnFilter,
      filter: "includes",
    },
    { Header: "Device ID", accessor: "device_id", Filter: DefaultColumnFilter },
    {
      Header: "App ID",
      accessor: "app_id",
      Cell: EditableSelect,
      Filter: SelectColumnFilter,
      filter: "includes",
    },
    {
      Header: "Disabled",
      accessor: "disabled",
      Cell: EditableCheckbox,
      Filter: DefaultColumnFilter,
    },
    {
      Header: "App Params",
      accessor: "app_params",
      Cell: EditableTextarea,
      disableFilters: true,
    },
  ];

  // Update the state when the user makes changes in the table
  const doUpdate = (rowIndex, columnId, value) => {
    setData((old) =>
      old.map((row, index) => {
        if (index === rowIndex) {
          return {
            ...row,
            [columnId]: value,
          };
        }
        return row;
      })
    );
  };

  return (
    <div className="admin-table">
      {data.length > 0 ? (
        <>
          <Table
            columns={columns}
            data={data}
            doUpdate={doUpdate}
            editable={editable}
          />
          <AdminTableControls
            data={data}
            setData={setData}
            editable={editable}
            setEditable={setEditable}
          />
        </>
      ) : (
        <div>Loading data...</div>
      )}
    </div>
  );
};

export default AdminTable;
