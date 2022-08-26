import React, { ComponentType, useContext } from "react";
import {
  LastFetchContext,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import Widget, { WidgetData } from "./widget";
import {
  ApiResponse,
  useSimulationApiResponse,
} from "Hooks/v2/use_api_response";

interface SimulationScreenLayoutProps {
  apiResponse: ApiResponse;
}

const SimulationScreenLayout: ComponentType<SimulationScreenLayoutProps> = ({
  apiResponse,
}) => {
  const responseMapper = useContext(ResponseMapperContext);
  const data = responseMapper(apiResponse);
  const { fullPage, flexZone } = data;

  return (
    <div className="simulation-screen-centering-container">
      <div className="simulation-screen-scrolling-container">
        {apiResponse && (
          <div className="simulation__full-page">
            <Widget data={fullPage ?? data} />
          </div>
        )}
        {flexZone?.length > 0 && (
          <div className="simulation__flex-zone">
            {flexZone.map((flexZonePage: WidgetData, index: number) => {
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
        )}
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
