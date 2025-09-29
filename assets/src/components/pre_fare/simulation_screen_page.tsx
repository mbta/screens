import { useParams } from "react-router";
import SimulationScreenContainer from "Components/pre_fare/simulation_screen_container";

const SimulationScreenPage = ({ opts = {} }) => {
  const { id } = useParams() as { id: string };
  return <SimulationScreenContainer id={id} opts={opts} />;
};

export default SimulationScreenPage;
