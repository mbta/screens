import React, { useRef, useMemo, useEffect } from "react";

import { gatherSelectOptions } from "Util/admin";

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

const EditableNumberInput = ({
  value: initialValue,
  row: { index },
  column: { id, mutator },
  doUpdate,
  editable,
}) => {
  const inputElt = useRef(null);

  const onBlur = () => {
    if (inputElt.current) {
      const value = parseInt(inputElt.current.value, 10);
      if (!isNaN(value)) {
        doUpdate(index, mutator || id, value);
      } else {
        alert(`Integer value expected in ${id} for Screen ID ${rowValues.id}`);
      }
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
  EditableNumberInput,
  EditableSelect,
  EditableCheckbox,
  EditableTextarea,
  IndeterminateCheckbox,
};
