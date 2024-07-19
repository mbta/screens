import React from "react";
import _ from "lodash";

import AdminForm from "Components/admin/admin_form";

const fetchConfig = async () => {
  const result = await fetch("/api/admin/");
  const resultJson = await result.json();

  // This sorts the entries alphanumerically by screen ID, and otherwise leaves the config alone.
  const screens = _.chain(JSON.parse(resultJson.config).screens)
    .toPairs()
    .sortBy(([screenId, _screenData]) => screenId)
    .fromPairs()
    .value();

  return { screens };
};

const AdminScreenConfigForm = (): JSX.Element => (
  <AdminForm
    fetchConfig={fetchConfig}
    validatePath="/api/admin/screens/validate"
    confirmPath="/api/admin/screens/confirm"
  />
);

export default AdminScreenConfigForm;
