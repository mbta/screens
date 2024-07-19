import React, { useState, useEffect, useRef } from "react";
import { doSubmit } from "Util/admin";

const validateJson = (json) => {
  try {
    JSON.parse(json);
    return true;
  } catch {
    return false;
  }
};

const AdminValidateControls = ({
  validatePath,
  setEditable,
  configRef,
}): JSX.Element => {
  const validateCallback = (resultJson) => {
    if (resultJson.success) {
      configRef.current.value = JSON.stringify(resultJson.config, null, 2);
      setEditable(false);
    } else if (resultJson.message) {
      alert(`Validation failed with message: ${resultJson.message}`);
    } else {
      alert("JSON is invalid!");
    }
  };

  const validateFn = () => {
    const config = configRef.current.value;
    if (validateJson(config)) {
      const dataToSubmit = { config };
      doSubmit(validatePath, dataToSubmit).then(validateCallback);
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

const AdminConfirmControls = ({
  confirmPath,
  setEditable,
  configRef,
}): JSX.Element => {
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
    doSubmit(confirmPath, dataToSubmit).then(confirmCallback);
  };

  return (
    <div>
      <button onClick={backFn}>Back</button>
      <button onClick={confirmFn}>Confirm</button>
    </div>
  );
};

const AdminForm = ({ fetchConfig, validatePath, confirmPath }): JSX.Element => {
  const [editable, setEditable] = useState(true);
  const configRef = useRef<HTMLTextAreaElement>(null);

  const setEditorContents = async () => {
    if (configRef.current) {
      const config = await fetchConfig();
      configRef.current.value = JSON.stringify(config, null, 2);
    }
  };

  useEffect(() => {
    setEditorContents();
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
          validatePath={validatePath}
          setEditable={setEditable}
          configRef={configRef}
        />
      ) : (
        <AdminConfirmControls
          confirmPath={confirmPath}
          setEditable={setEditable}
          configRef={configRef}
        />
      )}
    </div>
  );
};

export default AdminForm;
