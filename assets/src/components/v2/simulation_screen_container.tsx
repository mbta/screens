import React, { ComponentType, useContext } from "react";
import {
  LastFetchContext,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import Widget from "./widget";
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

  const renderFlexPage = (page) => {
    const slots = Object.keys(page);

    if (slots.length === 1) {
      return (
        <div className="flex-one-large">
          <div className="flex-one-large__large">
            <Widget data={page[slots[0]]} />
          </div>
        </div>
      );
    }

    if (slots.length === 2) {
      return (
        <div className="flex-two-medium">
          <div className="flex-two-medium__left">
            <Widget data={page[slots[0]]} />
          </div>
          <div className="flex-two-medium__right">
            <Widget data={page[slots[1]]} />
          </div>
        </div>
      );
    }
  };

  return (
    <div className="simulation-screen-container">
      {apiResponse && (
        <div className="simulation__full-page">
          <Widget data={fullPage} />
        </div>
      )}
      <div className="simulation__flex-zone">
        {flexZone.length &&
          flexZone.map((flexZonePage: any, index: number) => {
            return (
              <div
                key={`page${index}`}
                className="simulation__flex-zone-widget"
              >
                {renderFlexPage(flexZonePage)}
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
