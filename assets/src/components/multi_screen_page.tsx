import ScreenContainer from "Components/screen_container";
import { fetchDatasetValue } from "Util/dataset";

const MultiScreenPage = () => (
  <div className="multi-screen-page">
    {JSON.parse(fetchDatasetValue("screenIds")).map((id: string) => (
      <ScreenContainer id={id} key={id} />
    ))}
  </div>
);

export default MultiScreenPage;
