import React from "react";

import Header from "Components/solari/header";
import SectionList from "Components/solari/section_list";

import useApiResponse from "Hooks/use_api_response";

import { SOLARI_REFRESH_MS } from "Constants";

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header
        stationName={apiResponse.station_name}
        currentTimeString={apiResponse.current_time}
      />
      <SectionList
        sections={apiResponse.sections}
        currentTimeString={apiResponse.current_time}
      />
      <div className="screen-container__flex-space" />
    </div>
  );
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (apiResponse === null) {
    return null;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse(id, SOLARI_REFRESH_MS);
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
