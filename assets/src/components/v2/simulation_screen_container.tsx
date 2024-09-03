import React, { ComponentType, useContext } from "react";
import {
  LastFetchContext,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import Widget, { WidgetData } from "./widget";
import {
  ApiResponse,
  SimulationData,
  useSimulationApiResponse,
} from "Hooks/v2/use_api_response";
import WidgetTreeErrorBoundary from "Components/v2/widget_tree_error_boundary";

interface SimulationScreenLayoutProps {
  apiResponse: ApiResponse;
  opts: { [key: string]: any };
}

const SimulationScreenLayout: ComponentType<SimulationScreenLayoutProps> = ({
  apiResponse,
  opts,
}) => {
  const responseMapper = useContext(ResponseMapperContext);
  // See `ScreenLayout` for the explanation of this cast.
  const data = responseMapper(apiResponse) as SimulationData;
  const { fullPage, flexZone } = data;

  // If "alternateView" was provided as an option, we use the simulation version of screen normal
  // Currently only applies to DUPs
  const widgetData = opts.alternateView
    ? { ...fullPage, type: "simulation_screen_normal" }
    : fullPage;

  return (
    <div className="simulation-screen-centering-container">
      <div className="simulation-screen-scrolling-container">
        {apiResponse && (
          <div className="simulation__full-page">
            <WidgetTreeErrorBoundary>
              <Widget data={widgetData} />
            </WidgetTreeErrorBoundary>
          </div>
        )}
        {flexZone?.length > 0 && (
          <WidgetTreeErrorBoundary showFallbackOnError={false}>
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
          </WidgetTreeErrorBoundary>
        )}
      </div>
    </div>
  );
};

const SimulationScreenContainer = ({
  id,
  opts = {},
}: {
  id: string;
  opts?: { [key: string]: any };
}) => {
  const { apiResponse, lastSuccess } = useSimulationApiResponse({ id });

  return (
    <LastFetchContext.Provider value={lastSuccess}>
      <SimulationScreenLayout apiResponse={apiResponse} opts={opts} />
    </LastFetchContext.Provider>
  );
};

export default SimulationScreenContainer;
