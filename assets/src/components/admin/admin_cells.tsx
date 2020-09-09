import React, { useRef, useMemo, useEffect } from "react";
import _ from "lodash";

import { gatherSelectOptions } from "Util/admin";

const EditableCell = ({
  value: initialValue,
  row: { index },
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const onBlur = (e) => {
    const value = e.target.value;
    doUpdate(index, mutator || id, value);
  };

  return (
    <input
      defaultValue={initialValue}
      className={`admin-table__column--${id}`}
      onBlur={onBlur}
      disabled={!editable}
    />
  );
};

const EditableList = ({
  value: initialValue,
  row: { index },
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const onBlur = (e) => {
    const value = _.sortBy(e.target.value.split(","));
    doUpdate(index, mutator || id, value);
  };

  return (
    <input
      defaultValue={initialValue}
      className={`admin-table__column--${id}`}
      onBlur={onBlur}
      disabled={!editable}
    />
  );
};

const EditableNumberInput = ({
  value: initialValue,
  row: { index },
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const onBlur = (e) => {
    const value = parseInt(e.target.value, 10);
    if (!isNaN(value)) {
      doUpdate(index, mutator || id, value);
    } else {
      alert(`Integer value expected in ${id} for Screen ID ${rowValues.id}`);
    }
  };

  return (
    <input
      defaultValue={initialValue}
      className={`admin-table__column--${id}`}
      onBlur={onBlur}
      disabled={!editable}
    />
  );
};

const EditableCheckbox = ({
  value: initialValue,
  row: { index },
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const onChange = (e) => {
    const value = e.target.checked;
    doUpdate(index, mutator || id, value);
  };

  return (
    <input
      type="checkbox"
      defaultChecked={initialValue}
      onChange={onChange}
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

  const onChange = (e) => {
    const value = e.target.value;
    doUpdate(index, mutator || id, value);
  };

  return (
    <select
      defaultValue={initialValue}
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

const EditableTextarea = ({
  value: initialValue,
  row: { index, values: rowValues },
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const onBlur = (e) => {
    try {
      const json = JSON.parse(e.target.value);
      doUpdate(index, mutator || id, json);
    } catch (err) {
      alert(`Invalid JSON in ${id} for Screen ID ${rowValues.id}`);
    }
  };

  return (
    <textarea
      className="admin-table__textarea"
      defaultValue={JSON.stringify(initialValue, null, 2)}
      onBlur={onBlur}
      disabled={!editable}
    />
  );
};

const IndeterminateCheckbox = ({ indeterminate, ...rest }) => {
  const ref = useRef();

  useEffect(() => {
    ref.current.indeterminate = indeterminate;
  }, [ref, indeterminate]);

  return (
    <>
      <input type="checkbox" ref={ref} {...rest} />
    </>
  );
};

export {
  EditableCell,
  EditableList,
  EditableNumberInput,
  EditableSelect,
  EditableCheckbox,
  EditableTextarea,
  IndeterminateCheckbox,
};
