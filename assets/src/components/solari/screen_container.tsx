import React from "react";

import useApiResponse from "Hooks/use_api_response";

import Header from "Components/solari/header";
import SectionList from "Components/solar/section_list";

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header stationName={apiResponse.station_name} currentTimeString={apiResponse.current_time} />
      <SectionList sections={apiResponse.sections} currentTimeString={apiResponse.current_time} />
    </div>
  );
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse(id);
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
