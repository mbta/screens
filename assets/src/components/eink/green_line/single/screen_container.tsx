import React, { useEffect, useState } from "react";

import ConnectionError from "Components/eink/connection_error";
import DigitalBridge from "Components/eink/digital_bridge";
import Departures from "Components/eink/green_line/departures";
import Header from "Components/eink/green_line/header";
import LineMap from "Components/eink/green_line/line_map";
import { NoServiceTop } from "Components/eink/no_service";
import OvernightDepartures from "Components/eink/overnight_departures";

import useApiResponse from "Hooks/use_api_response";

const TopScreenLayout = ({
  currentTimeString,
  stopName,
  departures,
  stopId,
  routeId,
  lineMapData,
  headway,
  inlineAlert,
  serviceLevel
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
        height={1140}
        currentTimeString={currentTimeString}
      />
      <Departures
        departures={departures}
        headway={headway}
        destination={stopName}
        inlineAlert={inlineAlert}
        currentTimeString={currentTimeString}
        serviceLevel={serviceLevel}
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
  return <ConnectionError />;
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (!apiResponse || apiResponse.success === false) {
    return <NoConnectionScreenLayout />;
  }

  if (apiResponse.service_level === 5) {
    return <NoServiceScreenLayout />;
  }

  if (
    (!apiResponse.departures || apiResponse.departures.length === 0) &&
    apiResponse.headway === null
  ) {
    return <NoDeparturesScreenLayout apiResponse={apiResponse} />;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse(id);
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
