import React, { useMemo } from "react";

import { gatherSelectOptions } from "Util/admin";

// Filter Components
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

// Custom filter functions
const filterTags = (rows, id, filterValue) => {
  const tagsToFilter = filterValue.split(",");

  return rows.filter((row) => {
    const rowValue = row.values[id];
    return tagsToFilter.every((tag) => rowValue.includes(tag));
  });
};

export { DefaultColumnFilter, SelectColumnFilter, filterTags };
