import React from "react";

import NoConnectionSingle from "Components/eink/no_connection_single";
import DigitalBridge from "Components/eink/digital_bridge";
import Departures from "Components/eink/green_line/departures";
import Header from "Components/eink/green_line/header";
import LineMap from "Components/eink/green_line/line_map";
import { NoServiceTop } from "Components/eink/no_service";
import OvernightDepartures from "Components/eink/overnight_departures";
import TakeoverScreenLayout from "Components/eink/takeover_screen_layout";

import useApiResponse from "Hooks/use_api_response";

import { EINK_REFRESH_MS } from "Constants";
import LoadingTop from "Components/eink/loading_top";

const TopScreenLayout = ({
  currentTimeString,
  stopName,
  departures,
  stopId,
  routeId,
  lineMapData,
  headway,
  inlineAlert,
  serviceLevel,
  isHeadwayMode,
  psaUrl,
}): JSX.Element => {
  return (
    <div className="single-screen-container single-screen-container--gl-mercury">
      <Header
        stopName={stopName}
        routeId={routeId}
        currentTimeString={currentTimeString}
      />
      <LineMap
        data={lineMapData}
        height={1134}
        currentTimeString={currentTimeString}
        showVehicles={!isHeadwayMode}
      />
      <Departures
        departures={departures}
        headway={headway}
        destination={stopName}
        inlineAlert={inlineAlert}
        currentTimeString={currentTimeString}
        serviceLevel={serviceLevel}
        isHeadwayMode={isHeadwayMode}
        psaUrl={psaUrl}
      />
      <DigitalBridge stopId={stopId} />
    </div>
  );
};

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <TopScreenLayout
      currentTimeString={apiResponse.current_time}
      stopName={apiResponse.stop_name}
      departures={apiResponse.departures}
      stopId={apiResponse.stop_id}
      routeId={apiResponse.route_id}
      lineMapData={apiResponse.line_map}
      headway={apiResponse.headway}
      inlineAlert={apiResponse.inline_alert}
      serviceLevel={apiResponse.service_level}
      isHeadwayMode={apiResponse.is_headway_mode}
      psaUrl={apiResponse.psa_type === "departure" ? apiResponse.psa_url : null}
    />
  );
};

const NoServiceScreenLayout = (): JSX.Element => {
  // COVID Level 5 message
  return <NoServiceTop mode="subway" />;
};

const NoDeparturesScreenLayout = ({ apiResponse }): JSX.Element => {
  // We successfully fetched data, but there are no predictions, and we don't have
  // a headway for the current daypart. For now, we assume that it's the middle of
  // the night.
  return (
    <OvernightDepartures
      size="single"
      currentTimeString={apiResponse.currentTimeString}
    />
  );
};

const NoConnectionScreenLayout = (): JSX.Element => {
  // We weren't able to fetch data. Show a connection error message.
  return <NoConnectionSingle />;
};

const LoadingScreenLayout = (): JSX.Element => {
  // We haven't recieved a response since page load. Show a loading message.
  return <LoadingTop />;
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  switch (true) {
    case !apiResponse || apiResponse.success === false:
      return <NoConnectionScreenLayout />;
    case apiResponse.type === "loading":
      return <LoadingScreenLayout />;
    case apiResponse.psa_type === "takeover":
      return <TakeoverScreenLayout apiResponse={apiResponse} />;
    case apiResponse.service_level === 5:
      return <NoServiceScreenLayout />;
    case (!apiResponse.departures || apiResponse.departures.length === 0) &&
      apiResponse.headway === null:
      return <NoDeparturesScreenLayout apiResponse={apiResponse} />;
    default:
      return <DefaultScreenLayout apiResponse={apiResponse} />;
  }
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse({ id, refreshMs: EINK_REFRESH_MS });
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
