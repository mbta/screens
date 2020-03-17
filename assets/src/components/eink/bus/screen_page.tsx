import ScreenContainer from "Components/eink/bus/screen_container";
import React from "react";
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

export { ScreenPage, MultiScreenPage };
