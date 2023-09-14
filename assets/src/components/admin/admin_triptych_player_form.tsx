import React from "react";

import AdminForm from "Components/admin/admin_form";

const fetchConfig = async () => {
  const result = await fetch("/api/admin/triptych_players");
  const resultJson = await result.json();
  return JSON.parse(resultJson.config);
};

const AdminTriptychPlayerForm = (): JSX.Element => (
  <AdminForm
    fetchConfig={fetchConfig}
    validatePath="/api/admin/triptych_players/validate"
    confirmPath="/api/admin/triptych_players/confirm"
  />
);

export default AdminTriptychPlayerForm
