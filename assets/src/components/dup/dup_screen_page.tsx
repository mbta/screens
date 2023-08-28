import React from "react";
import { useParams } from "react-router-dom";

import { ROTATION_INDEX } from "./rotation_index";
import { NoDataLayout } from "Components/dup/screen_container";
import { isDup } from "Util/outfront";
import { useStationName } from "Hooks/outfront";
import { fetchDatasetValue } from "Util/dataset";
import { DUP_SIMULATION_REFRESH_MS } from "Constants";

const DupScreenPage = ({
  screenContainer: ScreenContainer,
}: {
  screenContainer: React.ComponentType;
}): JSX.Element => {
  const station = useStationName();

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
    <div className="simulation-screen-centering-container">
      <div className="simulation-screen-scrolling-container">
        <div className="projection">
          <ScreenContainer
            id={id}
            rotationIndex={0}
            refreshMs={DUP_SIMULATION_REFRESH_MS}
          />
          <ScreenContainer
            id={id}
            rotationIndex={1}
            refreshMs={DUP_SIMULATION_REFRESH_MS}
          />
          <ScreenContainer
            id={id}
            rotationIndex={2}
            refreshMs={DUP_SIMULATION_REFRESH_MS}
          />
        </div>
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
