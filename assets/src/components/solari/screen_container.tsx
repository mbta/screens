import React from "react";

import Header from "Components/solari/header";
import SectionList from "Components/solari/section_list";

import useApiResponse from "Hooks/use_api_response";

import { SOLARI_REFRESH_MS } from "Constants";
import { useLocation } from "react-router-dom";

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header
        stationName={apiResponse.station_name}
        currentTimeString={apiResponse.current_time}
      />
      <SectionList
        sections={apiResponse.sections}
        showSectionHeaders={apiResponse.show_section_headers}
        currentTimeString={apiResponse.current_time}
        key={apiResponse.current_time}
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
  const query = new URLSearchParams(useLocation().search);
  const date = query.get("date");
  const time = query.get("time");

  const apiResponse = useApiResponse(id, SOLARI_REFRESH_MS, date, time);
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
