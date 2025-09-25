import { useParams } from "react-router-dom";
import ScreenContainer from "Components/screen_container";
import { ScreenIDProvider } from "Hooks/use_screen_id";

interface ScreenPageProps {
  id?: string;
  paramKeys?: string[];
}

const ScreenPage = ({ id }: ScreenPageProps) => {
  const screenId = id ?? (useParams() as { id: string }).id;

  return (
    <ScreenIDProvider id={screenId}>
      <ScreenContainer id={screenId} />
    </ScreenIDProvider>
  );
};

export default ScreenPage;
