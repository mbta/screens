import React from "react";

import AdminForm from "Components/admin/admin_form";

const fetchConfig = async () => {
  const result = await fetch("/api/admin/");
  const resultJson = await result.json();
  return {
    screens: JSON.parse(resultJson.config).screens,
  };
};

const AdminScreenConfigForm = (): JSX.Element => (
  <AdminForm
    fetchConfig={fetchConfig}
    validatePath="/api/admin/screens/validate"
    confirmPath="/api/admin/screens/confirm"
  />
);

export default AdminScreenConfigForm;
