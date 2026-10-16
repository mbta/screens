import { useParams } from "react-router";
import ScreenContainer from "Components/screen_container";

const ScreenPage = ({ id }: { id?: string }) => {
  const params = useParams();
  const screenId = id ?? params.id;

  if (!screenId) return null;

  return <ScreenContainer id={screenId} />;
};

export default ScreenPage;
