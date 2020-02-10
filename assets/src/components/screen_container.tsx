import React, {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useRef,
  useState
} from "react";

import moment from "moment";
import "moment-timezone";

import DeparturesContainer from "./departures_container";
import DigitalBridge from "./digital_bridge";
import FareInfo from "./fare_info";
import FlexZoneContainer from "./flex_zone_container";
import Header from "./header";

const BottomScreenContainer = forwardRef(
  (
    {
      departureRows,
      inlineAlerts,
      globalAlert,
      departuresAlerts,
      stopId,
      numRows,
      currentTime,
      bottomNumRows,
      nearbyConnections
    },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <FlexZoneContainer
          inlineAlerts={inlineAlerts}
          globalAlert={globalAlert}
          departureRows={departureRows}
          numRows={numRows}
          currentTime={currentTime}
          departuresAlerts={departuresAlerts}
          bottomNumRows={bottomNumRows}
          nearbyConnections={nearbyConnections}
          ref={ref}
        />
        <FareInfo />
        <DigitalBridge stopId={stopId} />
      </div>
    );
  }
);

const TopScreenContainer = forwardRef(
  (
    {
      stopName,
      currentTimeString,
      departureRows,
      alerts,
      departuresAlerts,
      numRows
    },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <Header stopName={stopName} currentTimeString={currentTimeString} />
        <DeparturesContainer
          currentTimeString={currentTimeString}
          departureRows={departureRows}
          alerts={alerts}
          departuresAlerts={departuresAlerts}
          numRows={numRows}
          ref={ref}
        />
      </div>
    );
  }
);

const ScreenContainer = ({ id }): JSX.Element => {
  const [currentTimeString, setCurrentTimeString] = useState();
  const [stopName, setStopName] = useState();
  const [inlineAlerts, setInlineAlerts] = useState();
  const [globalAlert, setGlobalAlert] = useState();
  const [departureRows, setDepartureRows] = useState();
  const [departuresAlerts, setDeparturesAlerts] = useState();
  const [stopId, setStopId] = useState();
  const [nearbyConnections, setNearbyConnections] = useState();

  const doUpdate = async () => {
    const result = await fetch(`/api/${id}`);
    const json = await result.json();
    setCurrentTimeString(json.current_time);
    setStopName(json.stop_name);
    setInlineAlerts(json.inline_alerts);
    setGlobalAlert(json.global_alert);
    setDepartureRows(json.departure_rows);
    setDeparturesAlerts(json.departures_alerts);
    setStopId(json.stop_id);
    setNearbyConnections(json.nearby_connections);
  };

  useEffect(() => {
    doUpdate();

    const interval = setInterval(() => {
      doUpdate();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const [numRows, setNumRows] = useState(7);
  const ref = useRef(null);

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > 1312) {
      setNumRows(numRows - 1);
    }
  });

  const [bottomNumRows, setBottomNumRows] = useState(5);
  const bottomRef = useRef(null);
  useLayoutEffect(() => {
    if (bottomRef.current) {
      const height = bottomRef.current.clientHeight;
      if (height > 585) {
        setBottomNumRows(bottomNumRows - 1);
      }
    }
  });

  return (
    <div className="dual-screen-container">
      <TopScreenContainer
        stopName={stopName}
        currentTimeString={currentTimeString}
        departureRows={departureRows}
        alerts={inlineAlerts}
        departuresAlerts={departuresAlerts}
        numRows={numRows}
        ref={ref}
      />
      <BottomScreenContainer
        departureRows={departureRows}
        inlineAlerts={inlineAlerts}
        globalAlert={globalAlert}
        departuresAlerts={departuresAlerts}
        stopId={stopId}
        numRows={numRows}
        currentTime={currentTimeString}
        bottomNumRows={bottomNumRows}
        nearbyConnections={nearbyConnections}
        ref={bottomRef}
      />
    </div>
  );
};

export default ScreenContainer;
