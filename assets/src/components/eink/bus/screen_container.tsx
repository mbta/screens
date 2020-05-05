import React, { forwardRef, useRef } from "react";

import Departures from "Components/eink/bus/departures";
import FareInfo from "Components/eink/bus/fare_info";
import FlexZoneContainer from "Components/eink/bus/flex_zone_container";
import Header from "Components/eink/bus/header";
import ConnectionError from "Components/eink/connection_error";
import DigitalBridge from "Components/eink/digital_bridge";
import NoService from "Components/eink/no_service";
import OvernightDepartures from "Components/eink/overnight_departures";

import useApiResponse from "Hooks/use_api_response";
import useFitDepartures from "Hooks/use_fit_departures";

import { EINK_REFRESH_MS } from "Constants";

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
      psaName,
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
          psaName={psaName}
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
        psaName={apiResponse.psa_name}
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
  if (!apiResponse || apiResponse.success === false) {
    return <NoConnectionScreenLayout />;
  }

  if (apiResponse.service_level === 5) {
    return <NoServiceScreenLayout />;
  }

  if (!apiResponse.departures || apiResponse.departures.length === 0) {
    return <NoDeparturesScreenLayout apiResponse={apiResponse} />;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse(id, EINK_REFRESH_MS);
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout, useApiResponse };
