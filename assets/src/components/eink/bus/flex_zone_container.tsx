import React, { forwardRef } from "react";

import Departures from "Components/eink/bus/departures";
import { Props as DepartureGroupProps } from "Components/eink/bus/departure_group";
import NearbyConnections from "Components/eink/bus/nearby_connections";
import ServiceMap from "Components/eink/bus/service_map";
import GlobalAlert from "Components/eink/global_alert";
import TakeoverAlert from "Components/eink/takeover_alert";

type Props = Omit<DepartureGroupProps, "size"> & {
  globalAlert: object;
  nearbyConnections: object[];
  psaUrl: string;
};

const FlexZoneContainer = forwardRef<HTMLDivElement, Props>(
  (
    { currentTimeString, departures, globalAlert, nearbyConnections, psaUrl },
    ref,
  ): JSX.Element => {
    // Check whether there are any later departures to show
    const showLaterDepartures = departures && departures.length > 0;

    let topComponent;
    let bottomComponent;

    if (psaUrl) {
      return (
        <div className="flex-zone__container">
          <TakeoverAlert psaUrl={psaUrl} />
        </div>
      );
    } else if (showLaterDepartures && globalAlert) {
      // Later Departures + Alert
      topComponent = (
        <Departures
          currentTimeString={currentTimeString}
          departures={departures}
          size="small"
          ref={ref}
        />
      );
      bottomComponent = <GlobalAlert alert={globalAlert} />;
    } else if (showLaterDepartures) {
      // Later Departures + Nearby Connections
      topComponent = (
        <Departures
          currentTimeString={currentTimeString}
          departures={departures}
          size="small"
          ref={ref}
        />
      );
      bottomComponent = (
        <NearbyConnections nearbyConnections={nearbyConnections} />
      );
    } else if (globalAlert) {
      // Nearby Connections + Alert
      topComponent = (
        <NearbyConnections nearbyConnections={nearbyConnections} />
      );
      bottomComponent = <GlobalAlert alert={globalAlert} />;
    } else {
      // Nearby Connections + Service Map
      topComponent = (
        <NearbyConnections nearbyConnections={nearbyConnections} />
      );
      bottomComponent = <ServiceMap />;
    }

    return (
      <div className="flex-zone__container">
        <div className="flex-zone__top-container">{topComponent}</div>
        <div className="flex-zone__bottom-container">{bottomComponent}</div>
      </div>
    );
  },
);

export { Props };
export default FlexZoneContainer;
