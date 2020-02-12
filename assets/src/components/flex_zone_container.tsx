import React, { forwardRef } from "react";

import Departures from "./departures";
import FlexZoneAlert from "./flex_zone_alert";
import NearbyConnections from "./nearby_connections";
import ServiceMap from "./service_map";

const FlexZoneContainer = forwardRef(
  (
    {
      currentTimeString,
      departures,
      startIndex,
      endIndex,
      globalAlert,
      nearbyConnections
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

    if (showLaterDepartures && globalAlert) {
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
      bottomComponent = <FlexZoneAlert alert={globalAlert} />;
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
      bottomComponent = <FlexZoneAlert alert={globalAlert} />;
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
