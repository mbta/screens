import DebugErrorBoundary from "Components/helpers/debug_error_boundary";
import React, { useState } from "react";
import { useParams } from "react-router-dom";

import { useOutfrontStation } from "Hooks/use_outfront_tags";

const ScreenPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const station = useOutfrontStation();

  if (station !== null) {
    const id = `DUP-${station.replaceAll(" ", "")}`;
    return <ScreenContainer id={id} rotationIndex={0} />;
  } else {
    const { id, rotationIndex } = useParams();
    return <ScreenContainer id={id} rotationIndex={rotationIndex} />;
  }
};

const RotationPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const { id } = useParams();
  return (
    <div className="rotation-page">
      <ScreenContainer id={id} rotationIndex={0} />
      <ScreenContainer id={id} rotationIndex={1} />
      <ScreenContainer id={id} rotationIndex={2} />
    </div>
  );
};

const MultiRotationPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const screenIds = JSON.parse(
    document.getElementById("app").dataset.screenIds
  );

  return (
    <div className="rotation-page">
      {screenIds.map((id) => (
        <React.Fragment key={id}>
          <ScreenContainer id={id} rotationIndex={0} />
          <ScreenContainer id={id} rotationIndex={1} />
          <ScreenContainer id={id} rotationIndex={2} />
        </React.Fragment>
      ))}
    </div>
  );
};

export { ScreenPage, RotationPage, MultiRotationPage };
