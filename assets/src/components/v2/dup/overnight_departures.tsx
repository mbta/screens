import React, { ComponentType } from "react";
import { classWithModifier, imagePath } from "Util/util";
import RoutePill, { Pill } from "../departures/route_pill";

interface Props {
  routes: Pill[];
}

const OvernightDepartures: ComponentType<Props> = ({ routes }) => {
  return (
    <div className="overnight-departures__container">
      {routes.length ? (
        <img
          className={classWithModifier(
            "overnight-departures__image",
            "partial"
          )}
          src={imagePath(`dup_overnight_partial.png`)}
        />
      ) : (
        <img
          className={classWithModifier("overnight-departures__image", "full")}
          src={imagePath(`dup_overnight_full.png`)}
        />
      )}
      <div className="overnight-departures__text-container">
        <div className="overnight-departures__route-pill-container">
          {routes.map((route) => (
            <RoutePill {...route} key={route.color} />
          ))}
        </div>
        <div className="overnight-departures__text">
          Service resumes in the morning
        </div>
      </div>
    </div>
  );
};

export default OvernightDepartures;
