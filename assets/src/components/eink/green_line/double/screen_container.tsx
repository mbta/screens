import React, { useEffect, useState } from "react";

import ConnectionError from "Components/eink/connection_error";
import DigitalBridge from "Components/eink/digital_bridge";
import GlobalAlert from "Components/eink/global_alert";
import Departures from "Components/eink/green_line/departures";
import FareInfo from "Components/eink/green_line/fare_info";
import Header from "Components/eink/green_line/header";
import LineMap from "Components/eink/green_line/line_map";
import NearbyDepartures from "Components/eink/green_line/nearby_departures";
import NoService from "Components/eink/no_service";
import OvernightDepartures from "Components/eink/overnight_departures";
import TakeoverAlert from "Components/eink/takeover_alert";

import useApiResponse from "Hooks/use_api_response";

const TopScreenLayout = ({
  currentTimeString,
  stopName,
  departures,
  stopId,
  routeId,
  headway,
  lineMapData,
  inlineAlert
}): JSX.Element => {
  return (
    <div className="single-screen-container">
      <Header
        stopName={stopName}
        routeId={routeId}
        currentTimeString={currentTimeString}
      />
      <LineMap
        data={lineMapData}
        height={1312}
        currentTimeString={currentTimeString}
      />
      <Departures
        departures={departures}
        headway={headway}
        destination={stopName}
        inlineAlert={inlineAlert}
        currentTimeString={currentTimeString}
      />
    </div>
  );
};

const BottomScreenLayout = ({
  currentTimeString,
  globalAlert,
  stopId,
  nearbyDepartures,
  serviceLevel
}): JSX.Element => {
  if (serviceLevel > 1) {
    return (
      <div className="single-screen-container">
        <div className="flex-zone__container">
          <TakeoverAlert mode="subway" />
        </div>
        <FareInfo />
        <DigitalBridge stopId={stopId} />
      </div>
    );
  }

  return (
    <div className="single-screen-container">
      <div className="flex-zone__container">
        <div className="flex-zone__top-container">
          <NearbyDepartures
            data={nearbyDepartures}
            currentTimeString={currentTimeString}
          />
        </div>
        <div className="flex-zone__bottom-container">
          {globalAlert ? <GlobalAlert alert={globalAlert} /> : null}
        </div>
      </div>
      <FareInfo />
      <DigitalBridge stopId={stopId} />
    </div>
  );
};

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div>
      <TopScreenLayout
        currentTimeString={apiResponse.current_time}
        stopName={apiResponse.stop_name}
        departures={apiResponse.departures}
        stopId={apiResponse.stop_id}
        routeId={apiResponse.route_id}
        lineMapData={apiResponse.line_map}
        headway={apiResponse.headway}
        inlineAlert={apiResponse.inline_alert}
      />
      <BottomScreenLayout
        currentTimeString={apiResponse.current_time}
        globalAlert={apiResponse.global_alert}
        stopId={apiResponse.stop_id}
        nearbyDepartures={apiResponse.nearby_departures}
        serviceLevel={apiResponse.service_level}
      />
    </div>
  );
};

const NoServiceScreenLayout = (): JSX.Element => {
  // COVID Level 5 message
  return <NoService mode="subway" />;
};

const NoDeparturesScreenLayout = ({ apiResponse }): JSX.Element => {
  // We successfully fetched data, but there are no predictions, and we don't have
  // a headway for the current daypart. For now, we assume that it's the middle of
  // the night.
  return (
    <OvernightDepartures
      size="double"
      currentTimeString={apiResponse.currentTimeString}
    />
  );
};

const NoConnectionScreenLayout = (): JSX.Element => {
  // We weren't able to fetch data. Show a connection error message.
  return (
    <div>
      <ConnectionError />
      <ConnectionError />
    </div>
  );
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
