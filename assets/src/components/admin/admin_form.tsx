import React, { useState, useEffect, useRef } from "react";
import { doSubmit } from "Util/admin";

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

const AdminValidateControls = ({ setEditable, configRef }): JSX.Element => {
  const validateCallback = (resultJson) => {
    configRef.current.value = JSON.stringify(resultJson.config, null, 2);
    setEditable(false);
  };

  const validateFn = () => {
    const config = configRef.current.value;
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

const AdminConfirmControls = ({ setEditable, configRef }): JSX.Element => {
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
    const config = configRef.current.value;
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
  const configRef = useRef(null);

  const fetchConfig = async () => {
    const result = await fetch("/api/admin/");
    const json = await result.json();
    configRef.current.value = json.config;
  };

  useEffect(() => {
    fetchConfig();
    return;
  }, []);

  return (
    <div>
      <textarea
        ref={configRef}
        id="config"
        disabled={!editable}
        className="admin__textarea"
      />
      {editable ? (
        <AdminValidateControls
          setEditable={setEditable}
          configRef={configRef}
        />
      ) : (
        <AdminConfirmControls setEditable={setEditable} configRef={configRef} />
      )}
    </div>
  );
};

export default AdminForm;
