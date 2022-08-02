import React from "react";
import { useParams } from "react-router-dom";

import useOutfrontStation from "Hooks/use_outfront_station";
import { ROTATION_INDEX } from "./rotation_index";
import { NoDataLayout } from "Components/dup/screen_container";
import { isDup } from "Util/util";
import { fetchDatasetValue } from "Util/dataset";

const DupScreenPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const station = useOutfrontStation();

  if (station !== null) {
    const id = `DUP-${station.replace(/\s/g, "")}`;
    return <ScreenContainer id={id} rotationIndex={ROTATION_INDEX} />;
  } else {
    return <NoDataLayout code="0" />;
  }
};

const DevelopmentScreenPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const { id, rotationIndex } = useParams();
  return <ScreenContainer id={id} rotationIndex={rotationIndex} />;
};

const ScreenPage = ({
  screenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element =>
  isDup() ? (
    <DupScreenPage screenContainer={screenContainer} />
  ) : (
    <DevelopmentScreenPage screenContainer={screenContainer} />
  );

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

const SimulationPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const { id } = useParams();
  return (
    <div className="simulation-page">
      <div className="projection">
        <ScreenContainer id={id} rotationIndex={0} />
        <ScreenContainer id={id} rotationIndex={1} />
        <ScreenContainer id={id} rotationIndex={2} />
      </div>
    </div>
  );
};

const MultiRotationPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const screenIds = JSON.parse(fetchDatasetValue("screenIds")) as string[];

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

export { ScreenPage, RotationPage, MultiRotationPage, SimulationPage };
