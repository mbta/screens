import React, { useState } from "react";
import _ from "lodash";

import {
  FormTextCell,
  buildFormSelect,
} from "Components/admin/admin_form_cells";

const fields = [
  { key: "id", label: "Screen ID", FormCell: FormTextCell },
  {
    key: "app_id",
    label: "App ID",
    FormCell: buildFormSelect([
      "bus_eink",
      "gl_eink_single",
      "gl_eink_double",
      "solari",
    ]),
  },
  {
    key: "vendor",
    label: "Vendor",
    FormCell: buildFormSelect(["gds", "mercury", "solari", "c3ms"]),
  },
  { key: "device_id", label: "Device ID", FormCell: FormTextCell },
];

const defaultAppParamsByAppId = {
  bus_eink: { stop_id: "STOP_ID" },
  gl_eink_single: {
    stop_id: "STOP_ID",
    platform_id: "PLATFORM_ID",
    route_id: "ROUTE_ID",
    direction_id: -1,
  },
  gl_eink_double: {
    stop_id: "STOP_ID",
    platform_id: "PLATFORM_ID",
    route_id: "ROUTE_ID",
    direction_id: -1,
  },
  solari: { station_name: "STATION_NAME" },
};

const AddModal = ({ setData, setShowAddModal }): JSX.Element => {
  const initialFormValues = _.fromPairs(
    fields.map(({ key }) => [key, undefined])
  );
  const [formValues, setFormValues] = useState(initialFormValues);

  const addScreen = () => {
    const newRow = {
      app_id: formValues.app_id,
      app_params: defaultAppParamsByAppId[formValues.app_id],
      device_id: formValues.device_id,
      disabled: false,
      id: formValues.id,
      name: "",
      refresh_if_loaded_before: null,
      tags: [],
      vendor: formValues.vendor,
    };

    setData((data) => _.concat(data, newRow));
    setShowAddModal(false);
  };

  return (
    <div className="admin-modal__background">
      <div className="admin-modal__content">
        {fields.map(({ key, label, FormCell }) => (
          <div key={key}>
            <div>{label}</div>
            <FormCell header={key} setFormValues={setFormValues} />
          </div>
        ))}
        <div>
          <button onClick={addScreen}>Add</button>
          <button onClick={() => setShowAddModal(false)}>Cancel</button>
        </div>
      </div>
    </div>
  );
};

export default AddModal;
