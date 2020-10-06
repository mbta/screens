import React from "react";

import FullScreenTakeover from "Components/eink/full_screen_takeover";

const TakeoverScreenLayout = ({ apiResponse, size }): JSX.Element => {
  const psaName = apiResponse.psa_name;
  const srcPath = `https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/${psaName}`;
  return (
    <FullScreenTakeover
      srcPath={srcPath}
      currentTimeString={apiResponse.current_time}
    />
  );
};

export default TakeoverScreenLayout;
