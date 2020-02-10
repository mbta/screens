import moment from "moment";
import "moment-timezone";
import React, { forwardRef } from "react";

import FlexZoneAlert from "./flex_zone_alert";
import LaterDepartures from "./later_departures";
import NearbyConnections from "./nearby_connections";
import ServiceMap from "./service_map";

const FlexZoneContainer = forwardRef(
  (
    {
      inlineAlerts,
      globalAlert,
      departureRows,
      numRows,
      currentTime,
      departuresAlerts,
      bottomNumRows,
      nearbyConnections
    },
    ref
  ): JSX.Element => {
    // Check whether there are any later departures to show
    let showLaterDepartures;
    if (departureRows) {
      showLaterDepartures = numRows < departureRows.length;
    } else {
      showLaterDepartures = false;
    }

    let topComponent;
    let bottomComponent;

    if (showLaterDepartures && globalAlert) {
      // Later Departures + Alert
      topComponent = (
        <LaterDepartures
          departureRows={departureRows}
          startIndex={numRows}
          currentTime={currentTime}
          alerts={inlineAlerts}
          departuresAlerts={departuresAlerts}
          bottomNumRows={bottomNumRows}
          ref={ref}
        />
      );
      bottomComponent = <FlexZoneAlert alert={globalAlert} />;
    } else if (showLaterDepartures) {
      // Later Departures + Nearby Connections
      topComponent = (
        <LaterDepartures
          departureRows={departureRows}
          startIndex={numRows}
          currentTime={currentTime}
          alerts={inlineAlerts}
          departuresAlerts={departuresAlerts}
          bottomNumRows={bottomNumRows}
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
      <div className="flex-zone-container">
        <div className="flex-top-container">{topComponent}</div>
        <div className="flex-bottom-container">{bottomComponent}</div>
      </div>
    );
  }
);

export default FlexZoneContainer;
