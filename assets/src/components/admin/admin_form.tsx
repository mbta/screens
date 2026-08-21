import { useState, useEffect, useRef, type JSX, type RefObject } from "react";
import { AUTOLESS_ATTRIBUTES, fetch } from "Util/admin";

type AdminConfirmControlsProps = {
  onConfirm: (config: any) => Promise<{ success: boolean; error?: string }>;
  configRef: RefObject<HTMLTextAreaElement | null>;
  onCancel: () => void;
  onError: (string) => void;
  onSuccess: () => void;
};

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
  onConfirm,
  configRef,
  onCancel,
  onError,
  onSuccess,
}: AdminConfirmControlsProps): JSX.Element => {
  const [isLoading, setIsLoading] = useState(false);

  const confirmFn = async () => {
    setIsLoading(true);
    try {
      const config = configRef.current?.value;
      if (!config) {
        onError("No current configuration found.");
        return;
      }

      const parsedConfig = JSON.parse(config);
      const result = await onConfirm(parsedConfig);

      if (result.success === true) {
        onSuccess();
      } else if (result.error) {
        onError(result.error);
      } else {
        onError("An unknown error was returned from the server.");
      }
    } catch (error: unknown) {
      if (error instanceof Error) {
        onError(error.message);
      } else if (error && typeof error === "object" && "toString" in error) {
        onError(error.toString());
      } else {
        onError("An unknown exception occurred.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div>
      <button onClick={onCancel} disabled={isLoading}>
        Back
      </button>
      <button onClick={confirmFn} disabled={isLoading}>
        Confirm
      </button>
    </div>
  );
};

const AdminForm = ({
  fetchConfig,
  validatePath,
  onConfirm,
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
          onConfirm={onConfirm}
          configRef={configRef}
          onCancel={() => setEditable(true)}
          onError={(error) => {
            alert(`Config update failed: ${error}`);
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
