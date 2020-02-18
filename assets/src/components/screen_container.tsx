import React, {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useRef,
  useState
} from "react";

import ConnectionError from "./connection_error";
import Departures from "./departures";
import DigitalBridge from "./digital_bridge";
import FareInfo from "./fare_info";
import FlexZoneContainer from "./flex_zone_container";
import Header from "./header";
import OvernightDepartures from "./overnight_departures";

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
      nearbyConnections
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
          ref={ref}
        />
        <FareInfo />
        <DigitalBridge stopId={stopId} />
      </div>
    );
  }
);

const ScreenContainer = ({ id }): JSX.Element => {
  const [success, setSuccess] = useState();
  const [currentTimeString, setCurrentTimeString] = useState();
  const [stopName, setStopName] = useState();
  const [stopId, setStopId] = useState();
  const [departures, setDepartures] = useState();
  const [globalAlert, setGlobalAlert] = useState();
  const [nearbyConnections, setNearbyConnections] = useState();

  let version;

  const doUpdate = async () => {
    try {
      const result = await fetch(`/api/screen/${id}`);
      const json = await result.json();

      if (version === undefined) {
        version = json.version;
      } else if (version !== json.version) {
        window.location.reload(false);
      }

      setSuccess(json.success);
      setCurrentTimeString(json.current_time);
      setStopName(json.stop_name);
      setStopId(json.stop_id);
      setDepartures(json.departures);
      setGlobalAlert(json.global_alert);
      setNearbyConnections(json.nearby_connections);
    } catch (err) {
      setSuccess(false);
    }
  };

  useEffect(() => {
    doUpdate();

    const interval = setInterval(() => {
      doUpdate();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const [numRows, setNumRows] = useState(7);
  const [bottomNumRows, setBottomNumRows] = useState(5);
  const ref = useRef(null);
  const bottomRef = useRef(null);

  useLayoutEffect(() => {
    if (ref.current) {
      const height = ref.current.clientHeight;
      if (height > 1312) {
        setNumRows(numRows - 1);
      }
    }

    if (bottomRef.current) {
      const bottomHeight = bottomRef.current.clientHeight;
      if (bottomHeight > 585) {
        setBottomNumRows(bottomNumRows - 1);
      }
    }
  });

  if (success) {
    if (departures && departures.length > 0) {
      return (
        <div>
          <TopScreenContainer
            currentTimeString={currentTimeString}
            stopName={stopName}
            departures={departures}
            startIndex={0}
            endIndex={numRows}
            ref={ref}
          />
          <BottomScreenContainer
            currentTimeString={currentTimeString}
            departures={departures}
            startIndex={numRows}
            endIndex={numRows + bottomNumRows}
            globalAlert={globalAlert}
            stopId={stopId}
            nearbyConnections={nearbyConnections}
            ref={bottomRef}
          />
        </div>
      );
    } else {
      // We successfully fetched data, but there are no predictions.
      // For now, assume that this is because it's the middle of the night.
      return (
        <div>
          <OvernightDepartures />
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
