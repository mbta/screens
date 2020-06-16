import React from "react";

import Header from "Components/solari/header";
import SectionList from "Components/solari/section_list";
import Psa from "Components/solari/psa";

import useApiResponse from "Hooks/use_api_response";

import { SOLARI_REFRESH_MS } from "Constants";
import { useLocation } from "react-router-dom";

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header
        stationName={apiResponse.station_name}
        currentTimeString={apiResponse.current_time}
        sections={apiResponse.sections}
        overhead={false}
      />
      <SectionList
        overhead={false}
        sections={apiResponse.sections}
        sectionHeaders={apiResponse.section_headers}
        currentTimeString={apiResponse.current_time}
      />
      {apiResponse.psa_name && (
        <Psa
          psaName={apiResponse.psa_name}
          currentTimeString={apiResponse.current_time}
        />
      )}
    </div>
  );
};

const OverheadScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header
        stationName={apiResponse.station_name}
        currentTimeString={apiResponse.current_time}
        sections={apiResponse.sections}
        overhead={true}
      />
      <SectionList
        overhead={true}
        sections={apiResponse.sections}
        sectionHeaders={apiResponse.section_headers}
        currentTimeString={apiResponse.current_time}
      />
    </div>
  );
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (apiResponse === null) {
    return null;
  }

  if (apiResponse.overhead) {
    return <OverheadScreenLayout apiResponse={apiResponse} />;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const query = new URLSearchParams(useLocation().search);
  const datetime = query.get("datetime");

  const apiResponse = useApiResponse(id, SOLARI_REFRESH_MS, datetime);
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
