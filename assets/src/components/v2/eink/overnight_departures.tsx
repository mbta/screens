import moment from "moment";
import React, { ComponentType } from "react";
import { imagePath } from "Util/util";

const OvernightDepartures: ComponentType = () => {
  const currentTime = moment().tz("America/New_York").format("h:mm");

  return (
    <div className="overnight-departures__container">
      <div className="overnight-departures__time">{currentTime}</div>
      <img src={imagePath(`overnight-static-double.png`)} />
    </div>
  );
};

export default OvernightDepartures;
