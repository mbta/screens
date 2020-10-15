import React, { useState, useEffect } from "react";

import { doSubmit } from "Util/admin";

const DEVOPS_PATH = "/api/admin/devops";

const updateDisabledModes = async (disabledModes) => {
  const result = await doSubmit(DEVOPS_PATH, { disabled_modes: disabledModes });
  if (result.success !== true) {
    alert("Config update failed");
  }
};

const DisableModeRow = ({ mode, modeDisabled, onChange }) => {
  return (
    <tr>
      <td>{mode}</td>
      <td>
        <input type="checkbox" checked={modeDisabled} onChange={onChange} />
      </td>
    </tr>
  );
};

const Devops = () => {
  const [disabledModes, setDisabledModes] = useState([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    fetch("/api/admin/")
      .then((result) => result.json())
      .then((json) => JSON.parse(json.config))
      .then((config) => config.devops.disabled_modes)
      .then(setDisabledModes)
      .then((_) => setLoaded(true));
  }, []);

  useEffect(() => {
    if (loaded) {
      updateDisabledModes(disabledModes);
    }
  }, [disabledModes]);

  const modes = [
    { name: "Bus", id: "bus" },
    { name: "Subway", id: "subway" },
    { name: "Light Rail", id: "light_rail" },
    { name: "Commuter Rail", id: "commuter_rail" },
  ];

  return (
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
        {modes.map(({ name, id }) => {
          const onChange = (e) => {
            const disabled = e.target.checked;
            if (disabled) {
              setDisabledModes((ms) => [id, ...ms]);
            } else {
              setDisabledModes((ms) => ms.filter((m) => m !== id));
            }
          };

          return (
            <DisableModeRow
              mode={name}
              key={id}
              modeDisabled={disabledModes.includes(id)}
              onChange={onChange}
            />
          );
        })}
      </tbody>
    </table>
  );
};

export default Devops;
