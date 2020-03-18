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
import FareInfo from "Components/eink/green_line/fare_info";
import Header from "Components/eink/green_line/header";
import LineMap from "Components/eink/green_line/line_map";
import FlexZoneContainer from "Components/flex_zone_container";
import GlobalAlert from "Components/global_alert";
import NearbyDepartures from "Components/nearby_departures";
import OvernightDepartures from "Components/overnight_departures";
import TakeoverAlert from "Components/takeover_alert";

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
      headway,
      lineMapData,
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
          height={1312}
          currentTimeString={currentTimeString}
        />
        <Departures
          departures={departures}
          headway={headway}
          destination={stopName}
          inlineAlert={inlineAlert}
          currentTimeString={currentTimeString}
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
      nearbyDepartures,
      serviceLevel
    },
    ref
  ): JSX.Element => {
    if (serviceLevel > 1) {
      return (
        <div className="single-screen-container">
          <div className="flex-zone__container">
            <TakeoverAlert />
          </div>
          <FareInfo />
          <DigitalBridge stopId={stopId} />
        </div>
      );
    }

    return (
      <div className="single-screen-container">
        <div className="flex-zone__container">
          <div className="flex-zone__top-container">
            <NearbyDepartures
              data={nearbyDepartures}
              currentTimeString={currentTimeString}
            />
          </div>
          <div className="flex-zone__bottom-container">
            {globalAlert ? <GlobalAlert alert={globalAlert} /> : null}
          </div>
        </div>
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
  const [routeId, setRouteId] = useState();
  const [departures, setDepartures] = useState();
  const [globalAlert, setGlobalAlert] = useState();
  const [nearbyConnections, setNearbyConnections] = useState();
  const [nearbyDepartures, setNearbyDepartures] = useState();
  const [lineMapData, setLineMapData] = useState();
  const [headway, setHeadway] = useState();
  const [inlineAlert, setInlineAlert] = useState();
  const [serviceLevel, setServiceLevel] = useState(1);

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
      setNearbyDepartures(json.nearby_departures);
      setLineMapData(json.line_map);
      setHeadway(json.headway);
      setServiceLevel(json.service_level);
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

  if (success && departures) {
    if (departures.length === 0 && headway === null) {
      return (
        <div>
          <OvernightDepartures
            size="double"
            currentTimeString={currentTimeString}
          />
        </div>
      );
    } else {
      return (
        <div>
          <TopScreenContainer
            currentTimeString={currentTimeString}
            stopName={stopName}
            departures={departures}
            startIndex={0}
            endIndex={numRows}
            stopId={stopId}
            routeId={routeId}
            lineMapData={lineMapData}
            headway={headway}
            inlineAlert={inlineAlert}
            ref={ref}
          />
          <BottomScreenContainer
            currentTimeString={currentTimeString}
            departures={[]}
            startIndex={numRows}
            endIndex={numRows + bottomNumRows}
            globalAlert={globalAlert}
            stopId={stopId}
            nearbyConnections={nearbyConnections}
            nearbyDepartures={nearbyDepartures}
            serviceLevel={serviceLevel}
            ref={bottomRef}
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
