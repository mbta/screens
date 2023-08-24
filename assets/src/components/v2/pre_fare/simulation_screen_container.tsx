import React, { ComponentType, useContext } from "react";
import {
  LastFetchContext,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import Widget, { WidgetData } from "Components/v2/widget";
import {
  ApiResponse,
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
  const data = responseMapper(apiResponse);
  const { fullPage, flexZone } = data;
  let leftScreenPages: WidgetData[] = [];
  let rightScreenPages: WidgetData[] = [];
  if (flexZone) {
    leftScreenPages = flexZone.filter(
      (widget: WidgetData) => widget.type === "body_left_flex"
    );
    rightScreenPages = flexZone.filter(
      (widget: WidgetData) => !leftScreenPages.includes(widget)
    );
  }

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
            <div className="simulation__title">Live view</div>
            <WidgetTreeErrorBoundary>
              <Widget data={widgetData} />
            </WidgetTreeErrorBoundary>
          </div>
        )}
        {flexZone && <div className="divider"></div>}
        {leftScreenPages && leftScreenPages.length > 0 && (
          <div className="simulation__left-screen">
            <div className="simulation__title">
              Left panel ({leftScreenPages.length})
            </div>
            <div className="simulation__left-screen-widget-container">
              {leftScreenPages.map(
                (flexZonePage: WidgetData, index: number) => {
                  return (
                    <div
                      key={`page${index}`}
                      className="simulation__left-screen-widget"
                    >
                      <Widget data={flexZonePage} />
                    </div>
                  );
                }
              )}
            </div>
          </div>
        )}
        {rightScreenPages && rightScreenPages.length > 0 && (
          <div className="simulation__right-screen">
            <div className="simulation__title">
              Flex zone ({rightScreenPages.length})
            </div>
            <div className="simulation__right-screen-widget-container">
              {rightScreenPages.map(
                (flexZonePage: WidgetData, index: number) => {
                  return (
                    <div
                      key={`page${index}`}
                      className="simulation__right-screen-widget"
                    >
                      <Widget data={flexZonePage} />
                    </div>
                  );
                }
              )}
            </div>
          </div>
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
