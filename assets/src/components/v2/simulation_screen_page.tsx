import React from "react";
import { useParams } from "react-router-dom";
import SimulationScreenContainer from "./simulation_screen_container";

const SimulationScreenPage = ({opts = {}}) => {
  const { id } = useParams() as { id: string };
  return <SimulationScreenContainer id={id} opts={opts} />;
};

export default SimulationScreenPage;
