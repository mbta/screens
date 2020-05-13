import DebugErrorBoundary from "Components/helpers/debug_error_boundary";
import React, { useState } from "react";
import { useParams, useLocation } from "react-router-dom";

const MultiScreenPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const screenIds = JSON.parse(
    document.getElementById("app").dataset.screenIds
  );

  const query = new URLSearchParams(useLocation().search);
  const date = query.get("date");
  const time = query.get("time");

  return (
    <div className="multi-screen-page">
      {screenIds.map((id) => {
        if (date !== null && time !== null) {
          return <ScreenContainer id={id} date={date} time={time} key={id} />;
        } else {
          return <ScreenContainer id={id} key={id} />;
        }
      })}
    </div>
  );
};

const ScreenPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const { id } = useParams();

  const query = new URLSearchParams(useLocation().search);
  const date = query.get("date");
  const time = query.get("time");

  if (date !== null && time !== null) {
    return <ScreenContainer id={id} date={date} time={time} />;
  } else {
    return <ScreenContainer id={id} />;
  }
};

const AuditScreenPage = ({
  screenLayout: ScreenLayout,
}: {
  screenLayout: React.ComponentType;
}): JSX.Element => {
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
