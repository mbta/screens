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
}

const SimulationScreenLayout: ComponentType<SimulationScreenLayoutProps> = ({
  apiResponse,
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

  const isPageListActive = leftScreenPages && leftScreenPages.length > 1
                        && rightScreenPages && rightScreenPages.length > 1

  return (
    <div className="simulation-screen-centering-container">
      <div className="simulation-screen-scrolling-container">
        {apiResponse && (
          <div className="simulation__full-page">
            <div className="simulation__title">Live view</div>
            <div
              className="simulation"
              id={`simulation`}
            >
              <WidgetTreeErrorBoundary>
                <Widget data={fullPage} />
              </WidgetTreeErrorBoundary>
            </div>
          </div>
        )}
        {isPageListActive && <div className="divider"></div>}
        {leftScreenPages && leftScreenPages.length > 1 && (
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
                      className="simulation simulation__left-screen-widget"
                    >
                      <Widget data={flexZonePage} />
                    </div>
                  );
                }
              )}
            </div>
          </div>
        )}
        {rightScreenPages && rightScreenPages.length > 1 && (
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
                      className="simulation simulation__right-screen-widget"
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
}: {
  id: string;
  opts?: { [key: string]: any };
}) => {
  const { apiResponse, lastSuccess } = useSimulationApiResponse({ id });

  return (
    <LastFetchContext.Provider value={lastSuccess}>
      <SimulationScreenLayout apiResponse={apiResponse} />
    </LastFetchContext.Provider>
  );
};

export default SimulationScreenContainer;
