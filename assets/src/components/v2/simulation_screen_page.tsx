import React from "react";
import { useParams } from "react-router-dom";
import SimulationScreenContainer from "./simulation_screen_container";

const SimulationScreenPage = () => {
  const { id } = useParams();
  return <SimulationScreenContainer id={id} />;
};

export default SimulationScreenPage;
