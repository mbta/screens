import React, { ComponentType } from "react";
import { imagePath } from "Util/util";
import RoutePill, { Pill } from "../departures/route_pill";

interface Props {
  routes: Pill[];
}

const OvernightDepartures: ComponentType<Props> = ({ routes }) => {
  return (
    <div className="overnight-departures__container">
      <img
        className="overnight-departures__image"
        src={imagePath(`overnight-static-double.png`)}
      />
      <div className="overnight-departures__text-container">
        {/* <FreeText lines={text} /> */}
        <div className="overnight-departures__route-pill-container">
          {routes.map((route) => (
            <RoutePill {...route} />
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
