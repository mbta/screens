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
      "bus_eink_v2",
      "bus_shelter_v2",
      "dup",
      "gl_eink_single",
      "gl_eink_double",
      "gl_eink_v2",
      "solari",
      "solari_v2",
      "solari_large",
      "solari_large_v2",
      "pre_fare_v2",
    ]),
  },
  {
    key: "vendor",
    label: "Vendor",
    FormCell: buildFormSelect([
      "gds",
      "mercury",
      "solari",
      "c3ms",
      "outfront",
      "lg-mri",
    ]),
  },
  { key: "device_id", label: "Device ID", FormCell: FormTextCell },
];

const defaultAppParamsByAppId = {
  bus_eink: { stop_id: "STOP_ID" },
  bus_eink_v2: {
    departures: {},
    footer: {},
    header: {},
    alerts: {},
  },
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
  gl_eink_v2: {
    departures: {},
    footer: {},
    header: {},
    alerts: {},
  },
  solari: { station_name: "STATION_NAME" },
  dup: { header: "STATION_NAME" },
  bus_shelter_v2: {
    departures: {},
    footer: {},
    header: {},
    alerts: {},
  },
  solari_v2: {
    departures: {},
    header: {},
  },
  solari_large_v2: {
    departures: {},
    header: {},
  },
  pre_fare_v2: {
    header: {
      stop_name: "",
    },
  },
};

const initialFormValues = _.fromPairs(
  fields.map(({ key }) => [key, undefined])
);

const AddModal = ({ setData, closeModal }): JSX.Element => {
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
    closeModal();
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
          <button onClick={closeModal}>Cancel</button>
        </div>
      </div>
    </div>
  );
};

export default AddModal;
