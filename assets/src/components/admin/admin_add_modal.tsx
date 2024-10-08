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
      "bus_eink_v2",
      "bus_shelter_v2",
      "busway_v2",
      "dup_v2",
      "gl_eink_v2",
      "pre_fare_v2",
      "solari",
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

const commonV2Params = {
  header: { stop_id: "" },
  evergreen_content: [],
};

const departuresWidgetParams = { sections: [] };
const footerWidgetParams = { stop_id: "" };
const alertsWidgetParams = { stop_id: "" };

const defaultAppParamsByAppId = {
  bus_eink_v2: {
    ...commonV2Params,
    departures: departuresWidgetParams,
    footer: footerWidgetParams,
    alerts: alertsWidgetParams,
  },
  gl_eink_v2: {
    ...commonV2Params,
    departures: departuresWidgetParams,
    footer: footerWidgetParams,
    alerts: alertsWidgetParams,
  },
  solari: { station_name: "STATION_NAME" },
  dup_v2: {
    ...commonV2Params,
    primary_departures: departuresWidgetParams,
    secondary_departures: departuresWidgetParams,
    alerts: alertsWidgetParams,
  },
  bus_shelter_v2: {
    ...commonV2Params,
    departures: departuresWidgetParams,
    footer: footerWidgetParams,
    alerts: alertsWidgetParams,
  },
  busway_v2: {
    ...commonV2Params,
    departures: departuresWidgetParams,
  },
  pre_fare_v2: {
    ...commonV2Params,
  },
};

const initialFormValues = _.fromPairs(
  fields.map(({ key }) => [key, undefined]),
);

const AddModal = ({ setData, closeModal }): JSX.Element => {
  const [formValues, setFormValues] = useState(initialFormValues);

  const addScreen = () => {
    const newRow = {
      app_id: formValues.app_id,
      app_params: defaultAppParamsByAppId[formValues.app_id ?? 0],
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
            <FormCell value="" header={key} setFormValues={setFormValues} />
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
