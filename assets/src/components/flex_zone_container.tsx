import React, { forwardRef } from "react";

import Departures from "Components/eink/bus/departures";
import GlobalAlert from "Components/global_alert";
import NearbyConnections from "Components/nearby_connections";
import ServiceMap from "Components/service_map";
import TakeoverAlert from "Components/takeover_alert";

const FlexZoneContainer = forwardRef(
  (
    {
      currentTimeString,
      departures,
      startIndex,
      endIndex,
      globalAlert,
      nearbyConnections,
      serviceLevel
    },
    ref
  ): JSX.Element => {
    // Check whether there are any later departures to show
    let showLaterDepartures;
    if (departures) {
      showLaterDepartures = startIndex < departures.length;
    } else {
      showLaterDepartures = false;
    }

    let topComponent;
    let bottomComponent;

    if (serviceLevel > 1) {
      return (
        <div className="flex-zone__container">
          <TakeoverAlert mode="bus" />
        </div>
      );
    } else if (showLaterDepartures && globalAlert) {
      // Later Departures + Alert
      topComponent = (
        <Departures
          currentTimeString={currentTimeString}
          departures={departures}
          startIndex={startIndex}
          endIndex={endIndex}
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
          startIndex={startIndex}
          endIndex={endIndex}
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
  }
);

export default FlexZoneContainer;
