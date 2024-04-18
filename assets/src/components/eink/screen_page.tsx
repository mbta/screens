import DebugErrorBoundary from "Components/helpers/debug_error_boundary";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { fetchDatasetValue } from "Util/dataset";

const MultiScreenPage = ({ screenContainer: ScreenContainer }): JSX.Element => {
  const screenIds = JSON.parse(fetchDatasetValue("screenIds"));

  return (
    <div className="multi-screen-page">
      {screenIds.map((id) => (
        <ScreenContainer id={id} key={id} />
      ))}
    </div>
  );
};

type QueryParams = { id?: string }

const ScreenPage = ({ screenContainer: ScreenContainer }): JSX.Element => {
  const { id } = useParams<QueryParams>();
  return <ScreenContainer id={id} />;
};

const AuditScreenPage = ({ screenLayout: ScreenLayout }): JSX.Element => {
  const [data, setData] = useState("");

  const handleChange = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    setData(event.target.value);
  };

  const isDataValidJson = () => {
    let isValid = true;
    try {
      JSON.parse(data);
    } catch {
      isValid = false;
    }
    return isValid;
  };

  const parseData = () => {
    try {
      return JSON.parse(data);
    } catch {
      return "";
    }
  };

  const textareaProps = isDataValidJson()
    ? {}
    : { className: "audit-input-invalid" };

  return (
    <div className="audit-screen-page">
      <textarea
        value={data}
        onChange={handleChange}
        {...textareaProps}
      ></textarea>
      <DebugErrorBoundary>
        <ScreenLayout apiResponse={parseData()} />;
      </DebugErrorBoundary>
    </div>
  );
};

export { ScreenPage, MultiScreenPage, AuditScreenPage };
