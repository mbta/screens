import React from "react";
import { useParams } from "react-router-dom";
import ScreenContainer from "./screen_container";

const MultiScreenPage = (): JSX.Element => {
  return (
    <div className="multi-screen-page">
      {[...Array(19)].map((_, i) => (
        <ScreenContainer id={i + 1} key={i} />
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
