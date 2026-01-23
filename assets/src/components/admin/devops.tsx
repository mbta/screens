import { useState, useEffect } from "react";

import { fetch } from "Util/admin";

const DEVOPS_PATH = "/api/admin/devops";

const updateDisabledModes = async (disabledModes) => {
  const result = await fetch.post(DEVOPS_PATH, {
    disabled_modes: disabledModes,
  });
  if (result.success !== true) {
    alert("Config update failed");
  }
};

const Devops = () => {
  const [disabledModes, setDisabledModes] = useState<string[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    fetch
      .get("/api/admin")
      .then((response) => JSON.parse(response.config))
      .then((config) => config.devops.disabled_modes)
      .then(setDisabledModes)
      .then((_) => setLoaded(true))
      .catch((_) => alert("Failed to load config!"));
  }, []);

  const changeMode = async (id, isChecked) => {
    const newModes = isChecked
      ? [id, ...disabledModes]
      : disabledModes.filter((mode) => mode !== id);

    await updateDisabledModes(newModes);
    setDisabledModes(newModes);
  };

  const modes = [
    { name: "Bus", id: "bus" },
    { name: "Subway", id: "subway" },
    { name: "Light Rail", id: "light_rail" },
    { name: "Commuter Rail", id: "rail" },
  ];

  return (
    <main className="admin-page">
      <h2>Devops Flags</h2>
      <p>
        Disabling a mode here prevents any departures from being displayed for
        that mode.
      </p>
      <p>⚠️ Changes are applied immediately.</p>

      {loaded && (
        <table>
          <thead>
            <tr>
              <td>
                <strong>Mode</strong>
              </td>
              <td>
                <strong>Disabled?</strong>
              </td>
            </tr>
          </thead>
          <tbody>
            {modes.map(({ name, id }) => (
              <tr key={id}>
                <td>{name}</td>
                <td>
                  <input
                    type="checkbox"
                    checked={disabledModes.includes(id)}
                    onChange={(ev) => changeMode(id, ev.target.checked)}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </main>
  );
};

export default Devops;
