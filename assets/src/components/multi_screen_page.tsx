import ScreenContainer from "Components/screen_container";
import { fetchDatasetValue } from "Util/dataset";
import { ScreenIDProvider } from "Hooks/use_screen_id";

const MultiScreenPage = () => {
  const screenIds = JSON.parse(fetchDatasetValue("screenIdsWithOffsetMap"));

  return (
    <div className="multi-screen-page">
      {screenIds.map((screen) => (
        <div key={screen.id}>
          <ScreenIDProvider id={screen.id}>
            <ScreenContainer id={screen.id} />
          </ScreenIDProvider>
        </div>
      ))}
    </div>
  );
};

export default MultiScreenPage;
