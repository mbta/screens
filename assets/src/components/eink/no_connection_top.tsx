import moment from "moment";
import React from "react";
import { imagePath } from "Util/util";

const NoConnectionTop = (): JSX.Element => {
  const currentTime = moment().tz("America/New_York").format("h:mm");

  return (
    <div className="connection-error">
      <div className="connection-error__time">{currentTime}</div>
      <img src={imagePath("no-data-static-top.png")} />
    </div>
  );
};

export default NoConnectionTop;
