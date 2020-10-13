import React from "react";

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
import TakeoverScreenLayout from "Components/eink/takeover_screen_layout";

import useApiResponse from "Hooks/use_api_response";

import { EINK_REFRESH_MS } from "Constants";

const TopScreenLayout = ({
  currentTimeString,
  stopName,
  departures,
  stopId,
  routeId,
  headway,
  lineMapData,
  inlineAlert,
  isHeadwayMode,
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
        showVehicles={!isHeadwayMode}
      />
      <Departures
        departures={departures}
        headway={headway}
        destination={stopName}
        inlineAlert={inlineAlert}
        currentTimeString={currentTimeString}
        isHeadwayMode={isHeadwayMode}
      />
    </div>
  );
};

const BottomScreenLayout = ({
  currentTimeString,
  globalAlert,
  stopId,
  nearbyDepartures,
  psaUrl,
}): JSX.Element => {
  return (
    <div className="single-screen-container">
      <div className="flex-zone__container">
        {psaUrl ? (
          <TakeoverAlert psaUrl={psaUrl} />
        ) : (
          <>
            <div className="flex-zone__top-container">
              <NearbyDepartures
                data={nearbyDepartures}
                currentTimeString={currentTimeString}
              />
            </div>
            <div className="flex-zone__bottom-container">
              {globalAlert ? <GlobalAlert alert={globalAlert} /> : null}
            </div>
          </>
        )}
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
        isHeadwayMode={apiResponse.is_headway_mode}
      />
      <BottomScreenLayout
        currentTimeString={apiResponse.current_time}
        globalAlert={apiResponse.global_alert}
        stopId={apiResponse.stop_id}
        nearbyDepartures={apiResponse.nearby_departures}
        psaUrl={apiResponse.psa_url}
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
  switch (true) {
    case !apiResponse || apiResponse.success === false:
      return <NoConnectionScreenLayout />;
    case apiResponse.psa_type === "takeover" && apiResponse.psa_url !== null:
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
  const apiResponse = useApiResponse(id, EINK_REFRESH_MS);
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
