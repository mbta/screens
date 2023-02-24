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
  opts: {[key: string]: any}
}

const SimulationScreenLayout: ComponentType<SimulationScreenLayoutProps> = ({
  apiResponse,
  opts,
}) => {
  const responseMapper = useContext(ResponseMapperContext);
  const data = responseMapper(apiResponse);
  const { fullPage, flexZone } = data;
  
  // If "alternatePage" was provided as an option, we use the simulation version of screen normal
  // Currently only applies to DUPs
  const alternatePage = {...fullPage, type: "simulation_screen_normal"}   

  return (
    <div className="simulation-screen-centering-container">
      <div className="simulation-screen-scrolling-container">
        {apiResponse && (
          <div className="simulation__full-page">
            { opts.alternateView ? <Widget data={alternatePage} /> : <Widget data={fullPage ?? data} /> }
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

const SimulationScreenContainer = ({ id, opts = {} }: {id: string, opts?: {[key: string]: any}}) => {
  const { apiResponse, lastSuccess } = useSimulationApiResponse({ id });

  return (
    <LastFetchContext.Provider value={lastSuccess}>
      <SimulationScreenLayout apiResponse={apiResponse} opts={opts} />
    </LastFetchContext.Provider>
  );
};

export default SimulationScreenContainer;
