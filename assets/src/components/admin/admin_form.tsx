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

const doSubmit = async (path, data) => {
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
    return json;
  } catch (err) {
    alert("An error occurred.");
    throw err;
  }
};

const AdminValidateControls = ({ setEditable }): JSX.Element => {
  const validateCallback = (resultJson) => {
    document.getElementById("config").value = JSON.stringify(
      resultJson.config,
      null,
      2
    );
    setEditable(false);
  };

  const validateFn = () => {
    const config = document.getElementById("config").value;
    if (validateJson(config)) {
      const dataToSubmit = { config };
      doSubmit(VALIDATE_PATH, dataToSubmit).then(validateCallback);
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

const AdminConfirmControls = ({ setEditable }): JSX.Element => {
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
    const config = document.getElementById("config").value;
    const dataToSubmit = { config };
    doSubmit(CONFIRM_PATH, dataToSubmit).then(confirmCallback);
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

  const fetchConfig = async () => {
    const result = await fetch("/api/admin/");
    const json = await result.json();
    document.getElementById("config").value = json.config;
  };

  useEffect(() => {
    fetchConfig();
    return;
  }, []);

  return (
    <div>
      <textarea id="config" disabled={!editable} className="admin__textarea" />
      {editable ? (
        <AdminValidateControls setEditable={setEditable} />
      ) : (
        <AdminConfirmControls setEditable={setEditable} />
      )}
    </div>
  );
};

export default AdminForm;
