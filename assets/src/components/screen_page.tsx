import { useParams } from "react-router";
import ScreenContainer from "Components/screen_container";
import { ScreenIDProvider } from "Hooks/use_screen_id";

const ScreenPage = ({ id }: { id?: string }) => {
  const params = useParams();
  const screenId = id ?? params.id;

  if (!screenId) return null;

  return (
    <ScreenIDProvider id={screenId}>
      <ScreenContainer id={screenId} />
    </ScreenIDProvider>
  );
};

export default ScreenPage;
