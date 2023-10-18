import React from "react";
import _ from "lodash";

import AdminForm from "Components/admin/admin_form";

const fetchConfig = async () => {
  const result = await fetch("/api/admin/triptych_players");
  const resultJson = await result.json();

  // Sort the entries alphanumerically by player name.
  return _.chain(JSON.parse(resultJson.config))
    .toPairs()
    .sortBy(([playerName, _screenId]) => playerName)
    .fromPairs()
    .value();
};

const AdminTriptychPlayerForm = (): JSX.Element => (
  <AdminForm
    fetchConfig={fetchConfig}
    validatePath="/api/admin/triptych_players/validate"
    confirmPath="/api/admin/triptych_players/confirm"
  />
);

export default AdminTriptychPlayerForm
