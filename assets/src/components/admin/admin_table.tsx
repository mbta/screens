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

const buildDefaultMutator = (columnId) => {
  return (row, value) => {
    return { ...row, [columnId]: value };
  };
};

const buildIndexMapping = (data, dataFilter) => {
  // Map from index in filter to index in all data
  const [indexMapping, _filteredIndex] = data.reduce(
    ([acc, filteredIndex], row, index) => {
      const isIncluded = dataFilter(row);
      return [
        isIncluded ? { ...acc, [filteredIndex]: index } : acc,
        isIncluded ? filteredIndex + 1 : filteredIndex,
      ];
    },
    [{}, 0]
  );

  return indexMapping;
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
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const inputElt = useRef(null);

  const onBlur = () => {
    if (inputElt.current) {
      doUpdate(index, mutator || id, inputElt.current.value);
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
  column: { id, mutator, preFilteredRows },
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
      doUpdate(index, mutator || id, selectElt.current.value);
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
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const inputElt = useRef(null);

  const onChange = (e) => {
    if (inputElt.current) {
      doUpdate(index, mutator || id, inputElt.current.checked);
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
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const textareaElt = useRef(null);

  const onBlur = () => {
    if (textareaElt.current) {
      try {
        const json = JSON.parse(textareaElt.current.value);
        doUpdate(index, mutator || id, json);
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

const AdminTableControls = ({
  data,
  editable,
  setEditable,
  onValidate,
}): JSX.Element => {
  if (editable) {
    return (
      <div className="admin-table__controls">
        <button onClick={() => doValidate(data, onValidate)}>Validate</button>
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

const AdminTable = ({ columns, dataFilter }): JSX.Element => {
  const [data, setData] = useState([]);
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

    setData((orig) =>
      orig.map((row, index) => {
        const origIndex = indexMapping[rowIndex];
        if (index === origIndex) {
          return mutator(row, value);
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
            data={_.filter(data, dataFilter)}
            doUpdate={doUpdate}
            editable={editable}
            key={`table-${tableVersion}`}
          />
          <AdminTableControls
            data={data}
            editable={editable}
            setEditable={setEditable}
            onValidate={onValidate}
          />
        </>
      ) : (
        <div>Loading data...</div>
      )}
    </div>
  );
};

export {
  DefaultColumnFilter,
  SelectColumnFilter,
  EditableCell,
  EditableSelect,
  EditableCheckbox,
  EditableTextarea,
};
export default AdminTable;
