import React, { forwardRef, useRef } from "react";

import Departures from "Components/eink/bus/departures";
import FareInfo from "Components/eink/bus/fare_info";
import FlexZoneContainer from "Components/eink/bus/flex_zone_container";
import Header from "Components/eink/bus/header";
import ConnectionError from "Components/eink/connection_error";
import DigitalBridge from "Components/eink/digital_bridge";
import NoService from "Components/eink/no_service";
import OvernightDepartures from "Components/eink/overnight_departures";
import TakeoverScreenLayout from "Components/eink/takeover_screen_layout";

import useApiResponse from "Hooks/use_api_response";
import useFitDepartures from "Hooks/use_fit_departures";

import { EINK_REFRESH_MS } from "Constants";
import useSentry from "Hooks/use_sentry";

const TopScreenLayout = forwardRef(
  ({ currentTimeString, stopName, departures }, ref): JSX.Element => {
    return (
      <div className="single-screen-container">
        <Header stopName={stopName} currentTimeString={currentTimeString} />
        <Departures
          currentTimeString={currentTimeString}
          departures={departures}
          size="large"
          ref={ref}
        />
      </div>
    );
  }
);

const BottomScreenLayout = forwardRef(
  (
    {
      currentTimeString,
      departures,
      globalAlert,
      stopId,
      nearbyConnections,
      psaUrl,
    },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <FlexZoneContainer
          currentTimeString={currentTimeString}
          departures={departures}
          globalAlert={globalAlert}
          nearbyConnections={nearbyConnections}
          psaUrl={psaUrl}
          ref={ref}
        />
        <FareInfo />
        <DigitalBridge stopId={stopId} />
      </div>
    );
  }
);

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  const departuresRef = useRef(null);
  const laterDeparturesRef = useRef(null);

  const { departureCount, laterDepartureCount } = useFitDepartures(
    departuresRef,
    laterDeparturesRef
  );

  const departuresData = apiResponse.departures.slice(0, departureCount);
  const laterDeparturesData = apiResponse.departures.slice(
    departureCount,
    departureCount + laterDepartureCount
  );

  return (
    <div>
      <TopScreenLayout
        currentTimeString={apiResponse.current_time}
        stopName={apiResponse.stop_name}
        departures={departuresData}
        ref={departuresRef}
      />
      <BottomScreenLayout
        currentTimeString={apiResponse.current_time}
        departures={laterDeparturesData}
        globalAlert={apiResponse.global_alert}
        stopId={apiResponse.stop_id}
        nearbyConnections={apiResponse.nearby_connections}
        psaUrl={apiResponse.psa_url}
        ref={laterDeparturesRef}
      />
    </div>
  );
};

const NoServiceScreenLayout = (): JSX.Element => {
  // COVID Level 5 message
  return <NoService mode="bus" />;
};

const NoDeparturesScreenLayout = ({ apiResponse }): JSX.Element => {
  // We successfully fetched data, but there are no predictions.
  // For now, assume that this is because it's the middle of the night.
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
  const noDepartures = (apiResponse?.departures?.length ?? 0) === 0;
  useSentry();

  switch (true) {
    case !apiResponse || apiResponse.success === false:
      return <NoConnectionScreenLayout />;
    case apiResponse.psa_type === "takeover":
      return <TakeoverScreenLayout apiResponse={apiResponse} />;
    case apiResponse.service_level === 5:
      return <NoServiceScreenLayout />;
    case noDepartures && apiResponse.in_service_day:
      return <NoConnectionScreenLayout />;
    case noDepartures && !apiResponse.in_service_day:
      return <NoDeparturesScreenLayout apiResponse={apiResponse} />;
    default:
      return (
        <DefaultScreenLayout
          apiResponse={apiResponse}
          key={apiResponse.current_time}
        />
      );
  }
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse({ id, refreshMs: EINK_REFRESH_MS });
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout, useApiResponse };
