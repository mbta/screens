import moment from "moment";
import "moment-timezone";
import React from "react";

import FullScreenTakeover from "Components/eink/full_screen_takeover";
import { imagePath } from "Util/util";

const OvernightDepartures = ({ size, currentTimeString }): JSX.Element => {
  const srcPath = imagePath(`overnight-static-${size}.png`);
  return (
    <FullScreenTakeover
      srcPath={srcPath}
      currentTimeString={currentTimeString}
    />
  );
};

export default OvernightDepartures;
