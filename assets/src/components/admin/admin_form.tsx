import React, { useState, useEffect } from "react";

const VALIDATE_PATH = "/api/admin/validate";
const CONFIRM_PATH = "/api/admin/confirm";

const validateJson = (json) => {
  try {
    JSON.parse(json);
    return true;
  } catch (err) {
    return false;
  }
};

const doSubmit = async (path, data, callbackFn, errorFn) => {
  try {
    const csrfToken = document.head.querySelector("[name~=csrf-token][content]")
      .content;
    const result = await fetch(path, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-csrf-token": csrfToken,
      },
      credentials: "include",
      body: JSON.stringify(data),
    });
    const json = await result.json();
    callbackFn(json);
  } catch (err) {
    alert("An error occurred.");
  }
};

const AdminValidateControls = ({
  config,
  setConfig,
  setEditable,
}): JSX.Element => {
  const validateCallback = (resultJson) => {
    setConfig(JSON.stringify(resultJson.config, null, 2));
    setEditable(false);
  };

  const validateFn = () => {
    if (validateJson(config)) {
      const dataToSubmit = { config };
      doSubmit(VALIDATE_PATH, dataToSubmit, validateCallback);
    } else {
      alert("JSON is invalid!");
    }
  };

  return (
    <div>
      <button onClick={validateFn}>Validate</button>
    </div>
  );
};

const AdminConfirmControls = ({ config, setEditable }): JSX.Element => {
  const backFn = () => {
    setEditable(true);
  };

  const confirmCallback = (resultJson) => {
    if (resultJson.success === true) {
      alert("Config updated successfully");
      window.location.reload();
    } else {
      alert("Config update failed");
      setEditable(true);
    }
  };

  const confirmFn = () => {
    const dataToSubmit = { config };
    doSubmit(CONFIRM_PATH, dataToSubmit, confirmCallback);
  };

  return (
    <div>
      <button onClick={backFn}>Back</button>
      <button onClick={confirmFn}>Confirm</button>
    </div>
  );
};

const AdminForm = (): JSX.Element => {
  const [editable, setEditable] = useState(true);
  const [config, setConfig] = useState("");

  const fetchConfig = async () => {
    const result = await fetch("/api/admin/");
    const json = await result.json();
    setConfig(json.config);
  };

  useEffect(() => {
    fetchConfig();
    return;
  }, []);

  const updateConfig = (e) => {
    setConfig(e.target.value);
  };

  return (
    <div>
      <textarea
        id="config"
        disabled={!editable}
        className="admin__textarea"
        value={config}
        onChange={updateConfig}
      />
      {editable ? (
        <AdminValidateControls
          config={config}
          setEditable={setEditable}
          setConfig={setConfig}
        />
      ) : (
        <AdminConfirmControls config={config} setEditable={setEditable} />
      )}
    </div>
  );
};

export default AdminForm;
