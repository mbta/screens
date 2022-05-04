import React from "react";
import ScreenContainer, {
  ResponseMapper,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import { MappingContext } from "Components/v2/widget";

const MultiScreenPage = ({
  components,
  responseMapper,
}: {
  components: any;
  responseMapper: ResponseMapper;
}) => {
  const screenIds = JSON.parse(
    document.getElementById("app").dataset.screenIdsWithOffsetMap
  );

  return (
    <div className="multi-screen-page">
      {screenIds.map((screen) => (
        <div key={screen.id}>
          <MappingContext.Provider value={components}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <ScreenContainer id={screen.id} />
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </div>
      ))}
    </div>
  );
};

export default MultiScreenPage;
