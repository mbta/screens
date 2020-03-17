import React, {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useRef,
  useState
} from "react";

import ConnectionError from "Components/connection_error";
import DigitalBridge from "Components/digital_bridge";
import Departures from "Components/eink/green_line/departures";
import Header from "Components/eink/green_line/header";
import LineMap from "Components/eink/green_line/line_map";
import OvernightDepartures from "Components/overnight_departures";

const TopScreenContainer = forwardRef(
  (
    {
      currentTimeString,
      stopName,
      departures,
      startIndex,
      endIndex,
      stopId,
      routeId,
      lineMapData,
      headway,
      inlineAlert
    },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <Header
          stopName={stopName}
          routeId={routeId}
          currentTimeString={currentTimeString}
        />
        <LineMap
          data={lineMapData}
          height={1140}
          currentTimeString={currentTimeString}
        />
        <Departures
          departures={departures}
          headway={headway}
          destination={stopName}
          inlineAlert={inlineAlert}
          currentTimeString={currentTimeString}
        />
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
  const [routeId, setRouteId] = useState();
  const [departures, setDepartures] = useState();
  const [globalAlert, setGlobalAlert] = useState();
  const [nearbyConnections, setNearbyConnections] = useState();
  const [lineMapData, setLineMapData] = useState();
  const [headway, setHeadway] = useState();
  const [inlineAlert, setInlineAlert] = useState();

  const apiVersion = document.getElementById("app").dataset.apiVersion;

  const doUpdate = async () => {
    try {
      const result = await fetch(`/api/screen/${id}?version=${apiVersion}`);
      const json = await result.json();

      if (json.force_reload === true) {
        window.location.reload(false);
      }

      setSuccess(json.success);
      setCurrentTimeString(json.current_time);
      setStopName(json.stop_name);
      setStopId(json.stop_id);
      setRouteId(json.route_id);
      setDepartures(json.departures);
      setGlobalAlert(json.global_alert);
      setInlineAlert(json.inline_alert);
      setNearbyConnections(json.nearby_connections);
      setLineMapData(json.line_map);
      setHeadway(json.headway);
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
      if (height > 1140) {
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

  if (success && departures) {
    if (departures.length === 0 && headway === null) {
      return (
        <div>
          <OvernightDepartures
            size="single"
            currentTimeString={currentTimeString}
          />
        </div>
      );
    } else {
      return (
        <div>
          <TopScreenContainer
            stopId={stopId}
            currentTimeString={currentTimeString}
            stopName={stopName}
            departures={departures}
            startIndex={0}
            endIndex={numRows}
            routeId={routeId}
            lineMapData={lineMapData}
            headway={headway}
            inlineAlert={inlineAlert}
            ref={ref}
          />
        </div>
      );
    }
  } else {
    // We weren't able to fetch data. Show a connection error message.
    return (
      <div>
        <ConnectionError />
      </div>
    );
  }
};

export default ScreenContainer;
