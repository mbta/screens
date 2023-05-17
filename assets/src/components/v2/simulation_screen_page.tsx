import React from "react";
import { useParams } from "react-router-dom";
import SimulationScreenContainer from "./simulation_screen_container";
import { getDatasetValue } from "Util/dataset";

const SimulationScreenPage = ({ opts = {} }) => {
  const environmentName = getDatasetValue("environmentName");
  if (environmentName === "screens-prod") {
    window["_fs_run_in_iframe"] = true;
  }

  const { id } = useParams() as { id: string };
  return <SimulationScreenContainer id={id} opts={opts} />;
};

export default SimulationScreenPage;
