import React, { ComponentType, useContext } from "react";
import {
  LastFetchContext,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import Widget, { WidgetData } from "./widget";
import useSimulationApiResponse, {
  SimulationApiResponse,
} from "Hooks/v2/use_simulation_api_response";

interface SimulationScreenLayoutProps {
  apiResponse: SimulationApiResponse;
}

const SimulationScreenLayout: ComponentType<SimulationScreenLayoutProps> = ({
  apiResponse,
}) => {
  const responseMapper = useContext(ResponseMapperContext);
  const fullPage = responseMapper(apiResponse.fullPage);
  const flexZone = responseMapper(apiResponse.flexZone);

  return (
    <div className="simulation-screen-container">
      {apiResponse && (
        <div className="simulation__full-page">
          <Widget data={fullPage} />
        </div>
      )}
      <div className="simulation__flex-zone">
        {flexZone.length > 0 &&
          flexZone.map((flexZonePage: WidgetData, index: number) => {
            return (
              <div
                key={`page${index}`}
                className="simulation__flex-zone-widget"
              >
                <Widget data={flexZonePage} />
              </div>
            );
          })}
      </div>
    </div>
  );
};

const SimulationScreenContainer = ({ id }) => {
  const { apiResponse, lastSuccess } = useSimulationApiResponse({ id });

  return (
    <LastFetchContext.Provider value={lastSuccess}>
      <SimulationScreenLayout apiResponse={apiResponse} />
    </LastFetchContext.Provider>
  );
};

export default SimulationScreenContainer;
