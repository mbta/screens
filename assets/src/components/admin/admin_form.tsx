import { useState, useEffect, useRef } from "react";
import { AUTOLESS_ATTRIBUTES, fetch } from "Util/admin";

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
  configRef,
  onValidated,
}): JSX.Element => {
  const validateCallback = (resultJson) => {
    if (resultJson.success) {
      configRef.current.value = JSON.stringify(resultJson.config, null, 2);
      onValidated(resultJson.config);
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
      fetch.post(validatePath, dataToSubmit).then(validateCallback);
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
  configRef,
  onCancel,
  onError,
  onSuccess,
}): JSX.Element => {
  const confirmFn = () => {
    const config = configRef.current.value;
    const dataToSubmit = { config };
    fetch.post(confirmPath, dataToSubmit).then((resultJson) => {
      if (resultJson.success === true) {
        onSuccess();
      } else {
        onError();
      }
    });
  };

  return (
    <div>
      <button onClick={onCancel}>Back</button>
      <button onClick={confirmFn}>Confirm</button>
    </div>
  );
};

const AdminForm = ({
  fetchConfig,
  validatePath,
  confirmPath,
  onUpdated,
}): JSX.Element => {
  const [editable, setEditable] = useState(true);
  const configRef = useRef<HTMLTextAreaElement>(null);
  const [validatedConfig, setValidatedConfig] = useState(null);

  useEffect(() => {
    const setEditorContents = async () => {
      if (configRef.current) {
        const config = await fetchConfig();
        configRef.current.value = JSON.stringify(config, null, 2);
      }
    };

    setEditorContents();
  }, [fetchConfig]);

  return (
    <div className="admin-form">
      <textarea
        {...AUTOLESS_ATTRIBUTES}
        ref={configRef}
        id="config"
        disabled={!editable}
        className="admin__textarea"
      />
      {editable ? (
        <AdminValidateControls
          validatePath={validatePath}
          onValidated={(config) => {
            setEditable(false);
            setValidatedConfig(config);
          }}
          configRef={configRef}
        />
      ) : (
        <AdminConfirmControls
          confirmPath={confirmPath}
          configRef={configRef}
          onCancel={() => setEditable(true)}
          onError={() => {
            alert("Config update failed");
            setEditable(true);
          }}
          onSuccess={() => {
            onUpdated(validatedConfig);
            setEditable(true);
            setValidatedConfig(null);
          }}
        />
      )}
    </div>
  );
};

export default AdminForm;
