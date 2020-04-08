import React, {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useRef,
  useState
} from "react";

import ConnectionError from "Components/connection_error";
import DigitalBridge from "Components/digital_bridge";
import Departures from "Components/eink/bus/departures";
import FareInfo from "Components/eink/bus/fare_info";
import Header from "Components/eink/bus/header";
import FlexZoneContainer from "Components/flex_zone_container";
import { NoServiceBottom, NoServiceTop } from "Components/no_service";
import OvernightDepartures from "Components/overnight_departures";

const TopScreenContainer = forwardRef(
  (
    { currentTimeString, stopName, departures, startIndex, endIndex },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <Header stopName={stopName} currentTimeString={currentTimeString} />
        <Departures
          currentTimeString={currentTimeString}
          departures={departures}
          startIndex={startIndex}
          endIndex={endIndex}
          size="large"
          ref={ref}
        />
      </div>
    );
  }
);

const BottomScreenContainer = forwardRef(
  (
    {
      currentTimeString,
      departures,
      startIndex,
      endIndex,
      globalAlert,
      stopId,
      nearbyConnections,
      serviceLevel
    },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <FlexZoneContainer
          currentTimeString={currentTimeString}
          departures={departures}
          startIndex={startIndex}
          endIndex={endIndex}
          globalAlert={globalAlert}
          nearbyConnections={nearbyConnections}
          serviceLevel={serviceLevel}
          ref={ref}
        />
        <FareInfo />
        <DigitalBridge stopId={stopId} />
      </div>
    );
  }
);

const ScreenContainer = ({ id }): JSX.Element => {
  const [apiResponse, setApiResponse] = useState(null);
  const apiVersion = document.getElementById("app").dataset.apiVersion;

  const doUpdate = async () => {
    try {
      const result = await fetch(`/api/screen/${id}?version=${apiVersion}`);
      const json = await result.json();

      if (json.force_reload === true) {
        window.location.reload(false);
      }
      setApiResponse(json);
    } catch (err) {
      setApiResponse({ success: false });
    }
  };

  useEffect(() => {
    doUpdate();

    const interval = setInterval(() => {
      doUpdate();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  // Fit as many rows as will fit in departures and later departures
  const MAX_DEPARTURE_ROWS = 7;
  const MAX_LATER_DEPARTURE_ROWS = 5;
  const MAX_DEPARTURES_HEIGHT = 1312;
  const MAX_LATER_DEPARTURES_HEIGHT = 585;

  const [departureCount, setDepartureCount] = useState(MAX_DEPARTURE_ROWS);
  const [laterDepartureCount, setLaterDepartureCount] = useState(
    MAX_LATER_DEPARTURE_ROWS
  );
  const departuresRef = useRef(null);
  const laterDeparturesRef = useRef(null);

  useLayoutEffect(() => {
    if (departuresRef.current) {
      const departuresHeight = departuresRef.current.clientHeight;
      if (departuresHeight > MAX_DEPARTURES_HEIGHT) {
        setDepartureCount(departureCount - 1);
      }
    }

    if (laterDeparturesRef.current) {
      const laterDeparturesHeight = laterDeparturesRef.current.clientHeight;
      if (laterDeparturesHeight > MAX_LATER_DEPARTURES_HEIGHT) {
        setLaterDepartureCount(laterDepartureCount - 1);
      }
    }
  });

  if (apiResponse && apiResponse.success) {
    if (apiResponse && apiResponse.serviceLevel === 5) {
      return (
        <div>
          <NoServiceTop mode="bus" />
          <NoServiceBottom />
        </div>
      );
    } else if (
      apiResponse &&
      apiResponse.departures &&
      apiResponse.departures.length > 0
    ) {
      return (
        <div>
          <TopScreenContainer
            currentTimeString={apiResponse.current_time}
            stopName={apiResponse.stop_name}
            departures={apiResponse.departures}
            startIndex={0}
            endIndex={departureCount}
            ref={departuresRef}
          />
          <BottomScreenContainer
            currentTimeString={apiResponse.current_time}
            departures={apiResponse.departures}
            startIndex={departureCount}
            endIndex={departureCount + laterDepartureCount}
            globalAlert={apiResponse.global_alert}
            stopId={apiResponse.stop_id}
            nearbyConnections={apiResponse.nearbyConnections}
            serviceLevel={apiResponse.service_level}
            ref={laterDeparturesRef}
          />
        </div>
      );
    } else {
      // We successfully fetched data, but there are no predictions.
      // For now, assume that this is because it's the middle of the night.
      return (
        <div>
          <OvernightDepartures
            size="double"
            currentTimeString={apiResponse.currentTimeString}
          />
        </div>
      );
    }
  } else {
    // We weren't able to fetch data. Show a connection error message.
    return (
      <div>
        <ConnectionError />
        <ConnectionError />
      </div>
    );
  }
};

export default ScreenContainer;
