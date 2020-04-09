import ScreenContainer, {
  ScreenLayout
} from "Components/eink/green_line/single/screen_container";
import React, { useState } from "react";
import { useParams } from "react-router-dom";

const MultiScreenPage = (): JSX.Element => {
  const screenIds = JSON.parse(
    document.getElementById("app").dataset.screenIds
  );

  return (
    <div className="multi-screen-page">
      {screenIds.map(id => (
        <ScreenContainer id={id} key={id} />
      ))}
    </div>
  );
};

const ScreenPage = (): JSX.Element => {
  const { id } = useParams();
  return (
    <div>
      <ScreenContainer id={id} />
    </div>
  );
};

const AuditScreenPage = (): JSX.Element => {
  const [data, setData] = useState("");

  const handleChange = event => {
    setData(JSON.parse(event.target.value));
  };

  return (
    <div className="audit-screen-page">
      <textarea value={JSON.stringify(data)} onChange={handleChange}></textarea>
      <ScreenLayout apiResponse={data} />;
    </div>
  );
};

export { ScreenPage, MultiScreenPage, AuditScreenPage };
