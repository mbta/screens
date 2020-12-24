import DebugErrorBoundary from "Components/helpers/debug_error_boundary";
import React, { useState } from "react";
import { useParams } from "react-router-dom";

const ScreenPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const { id, rotationIndex } = useParams();
  return <ScreenContainer id={id} rotationIndex={rotationIndex} />;
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
        <>
          <ScreenContainer id={id} rotationIndex={0} key={`${id}-0`} />
          <ScreenContainer id={id} rotationIndex={1} key={`${id}-1`} />
          <ScreenContainer id={id} rotationIndex={2} key={`${id}-2`} />
        </>
      ))}
    </div>
  );
};

export { ScreenPage, RotationPage, MultiRotationPage };
