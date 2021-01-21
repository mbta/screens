import React, { useState, useEffect, useRef } from "react";

import { standardTimeRepresentation } from "Util/time_representation";

import BaseDepartureTime from "Components/eink/base_departure_time";
import BaseDepartureDestination from "Components/eink/base_departure_destination";
import InlineAlertBadge from "Components/solari/inline_alert_badge";
import {
  DepartureRoutePill,
  PlaceholderRoutePill,
} from "Components/solari/route_pill";

import { classWithModifier, classWithModifiers, imagePath } from "Util/util";

const NormalDepartureTimeAndCrowding = ({
  crowdingLevel,
  timeRepresentation,
  timeAnimationModifier,
}) => {
  return (
    <>
      <div className={classWithModifier("departure-crowding", "normal")}>
        {crowdingLevel && (
          <img
            className="departure-crowding__image--normal"
            src={imagePath(`crowding-color-level-${crowdingLevel}.svg`)}
          />
        )}
      </div>
      <div
        className={classWithModifier("departure-time", timeAnimationModifier)}
      >
        <BaseDepartureTime time={timeRepresentation} />
      </div>
    </>
  );
};

const OverheadDepartureTimeAndCrowding = ({
  crowdingLevel,
  timeRepresentation,
  timeAnimationModifier: arrivingModifier,
  currentTimeString,
}) => {
  const [showCrowding, setShowCrowding] = useState(false);
  const ref = useRef(null);

  // When we load new data, show the time, which is styled to animate in from the right.
  useEffect(() => {
    setShowCrowding(false);
  }, [currentTimeString]);

  // Timing is controlled by the timings on the animation. The animation on the time element
  // ends after 10s, then the animationend event toggles crowding on.
  useEffect(() => {
    const onAnimationEnd = (e) => {
      setShowCrowding(true);
    };

    if (ref.current) {
      ref.current.addEventListener("animationend", onAnimationEnd);
      return () => {
        if (ref.current) {
          ref.current.removeEventListener("animationend", onAnimationEnd);
        }
      };
    }
  });

  const timeModifiers = crowdingLevel
    ? [arrivingModifier, "overhead-with-crowding"]
    : [arrivingModifier];

  return (
    <>
      {showCrowding ? (
        <div className={classWithModifier("departure-crowding", "overhead")}>
          {crowdingLevel && (
            <img
              className="departure-crowding__image--overhead"
              src={imagePath(`crowding-color-level-${crowdingLevel}.svg`)}
            />
          )}
        </div>
      ) : (
          <div
            className={classWithModifiers("departure-time", timeModifiers)}
            ref={ref}
          >
            <BaseDepartureTime time={timeRepresentation} />
          </div>
        )}
    </>
  );
};

const Departure = ({
  route,
  routeId,
  destination,
  time,
  currentTimeString,
  vehicleStatus,
  stopType,
  alerts,
  crowdingLevel,
  overhead,
  groupStart,
  groupEnd,
}): JSX.Element => {
  const viaPattern = /(.+) (via .+)/;
  const parenPattern = /(.+) (\(.+)/;

  const viaModifier =
    destination &&
      (viaPattern.test(destination) || parenPattern.test(destination))
      ? "with-via"
      : "no-via";

  const timeRepresentation = standardTimeRepresentation(
    time,
    currentTimeString,
    vehicleStatus,
    stopType
  );

  const timeAnimationModifier =
    timeRepresentation.type === "TEXT" ? "animated" : "static";

  const containerModifiers = [];
  if (groupStart) {
    containerModifiers.push("group-start");
  }
  if (groupEnd) {
    containerModifiers.push("group-end");
  }

  return (
    <div
      className={classWithModifiers("departure-container", containerModifiers)}
    >
      <div className={classWithModifier("departure", viaModifier)}>
        {groupStart ? (
          <DepartureRoutePill route={route} routeId={routeId} />
        ) : (
            <PlaceholderRoutePill />
          )}
        <div className="departure-destination">
          {destination && groupStart && (
            <BaseDepartureDestination destination={destination} />
          )}
        </div>

        {overhead ? (
          <OverheadDepartureTimeAndCrowding
            crowdingLevel={crowdingLevel}
            timeRepresentation={timeRepresentation}
            timeAnimationModifier={timeAnimationModifier}
            currentTimeString={currentTimeString}
          />
        ) : (
            <NormalDepartureTimeAndCrowding
              crowdingLevel={crowdingLevel}
              timeRepresentation={timeRepresentation}
              timeAnimationModifier={timeAnimationModifier}
            />
          )}

        {groupStart && alerts.length > 0 && (
          <div className="departure__alerts-container">
            {alerts.map((alert) => (
              <InlineAlertBadge alert={alert} key={alert} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Departure;
