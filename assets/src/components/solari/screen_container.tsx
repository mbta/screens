import React from "react";

import Header from "Components/solari/header";
import SectionListContainer from "Components/solari/section_list_container";
import Psa from "Components/solari/psa";

import { classWithModifier } from "Util/util";

import useApiResponse from "Hooks/use_api_response";

import { SOLARI_REFRESH_MS } from "Constants";
import { useLocation } from "react-router-dom";

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  const sizeModifier = apiResponse.overhead ? "size-large" : "size-normal";

  return (
    <div className={classWithModifier("screen-container", sizeModifier)}>
      <Header
        stationName={apiResponse.station_name}
        sections={apiResponse.sections}
        currentTimeString={apiResponse.current_time}
        overhead={apiResponse.overhead}
      />
      <SectionListContainer
        sections={apiResponse.sections}
        sectionHeaders={apiResponse.section_headers}
        currentTimeString={apiResponse.current_time}
        overhead={apiResponse.overhead}
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

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (apiResponse === null) {
    return null;
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
