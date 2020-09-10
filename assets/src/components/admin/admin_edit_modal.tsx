import React, { useState } from "react";
import _ from "lodash";

const EditModal = ({
  columns,
  data,
  setData,
  selectedRowIds,
  setShowEditModal,
  setTableVersion,
  doUpdate,
}) => {
  const selectedRows = _.filter(data, (_row, i) => selectedRowIds[i]);

  const initialFormValues = _.fromPairs(
    columns.map(({ Header }) => [Header, undefined])
  );
  const [formValues, setFormValues] = useState(initialFormValues);

  const applyChanges = () => {
    columns.forEach(({ Header, FormCell, id, accessor, mutator }) => {
      const value = formValues[Header];
      if (value !== undefined) {
        const columnIdOrMutator =
          typeof accessor === "function" ? mutator : accessor;
        _.forEach(selectedRowIds, (selected, rowIndex) => {
          if (selected === true) {
            doUpdate(rowIndex, columnIdOrMutator, value);
          }
        });
      }
    });

    setTableVersion((version) => version + 1);
    setShowEditModal(false);
  };

  return (
    <div className="admin-modal__background">
      <div className="admin-modal__content">
        {columns.map(({ Header, FormCell, accessor }, i) => {
          if (FormCell) {
            const selectedRowValues = selectedRows.map((row) => {
              if (typeof accessor === "function") {
                return accessor(row);
              } else {
                return row[accessor];
              }
            });

            const firstValue = selectedRowValues[0];
            const otherValues = selectedRowValues.slice(
              1,
              selectedRowValues.length
            );
            const valuesAllMatch = _.every(otherValues, (otherValue) =>
              _.isEqual(firstValue, otherValue)
            );
            const value = valuesAllMatch ? firstValue : undefined;

            return (
              <div key={Header}>
                <div>{Header}</div>
                <FormCell
                  value={value}
                  header={Header}
                  setFormValues={setFormValues}
                />
              </div>
            );
          }

          return null;
        })}
        <button onClick={applyChanges}>Apply Changes</button>
        <button onClick={() => setShowEditModal(false)}>Discard Changes</button>
      </div>
    </div>
  );
};

export default EditModal;
