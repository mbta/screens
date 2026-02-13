import _ from "lodash";
import { type JSX } from "react";

import AdminForm from "Components/admin/admin_form";
import { fetch } from "Util/admin";

const fetchConfig = async () => {
  const { config } = await fetch.get("/api/admin");

  // This sorts the entries alphanumerically by screen ID, and otherwise leaves the config alone.
  const screens = _.chain(JSON.parse(config).screens)
    .toPairs()
    .sortBy(([screenId, _screenData]) => screenId)
    .fromPairs()
    .value();

  return { screens };
};

const AdminScreenConfigForm = (): JSX.Element => (
  <main className="admin-page">
    <h2>Config Editor</h2>
    <AdminForm
      fetchConfig={fetchConfig}
      validatePath="/api/admin/screens/validate"
      confirmPath="/api/admin/screens/confirm"
      onUpdated={() => alert("Config updated successfully")}
    />
  </main>
);

export default AdminScreenConfigForm;
