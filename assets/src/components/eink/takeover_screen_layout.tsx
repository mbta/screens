import React from "react";

import FullScreenTakeover from "Components/eink/full_screen_takeover";

const TakeoverScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <FullScreenTakeover
      srcPath={apiResponse.psa_url}
      currentTimeString={apiResponse.current_time}
    />
  );
};

export default TakeoverScreenLayout;
