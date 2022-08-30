import moment from "moment";
import React from "react";
import { imagePath } from "Util/util";

const NoConnectionSingle = (): JSX.Element => {
  const currentTime = moment().tz("America/New_York").format("h:mm");

  return (
    <div className="connection-error">
      <div className="connection-error__time">{currentTime}</div>
      <img src={imagePath("no-data-static-single.png")} />
    </div>
  );
};

export default NoConnectionSingle;
