import React from "react";

import Header from "Components/dup/header";
import SectionList from "Components/dup/section_list";

import useApiResponse from "Hooks/use_api_response";
import { DUP_REFRESH_MS } from "Constants";

const DefaultScreenLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header
        text={apiResponse.header}
        currentTimeString={apiResponse.current_time}
      />
      <SectionList
        sections={apiResponse.sections}
        currentTimeString={apiResponse.current_time}
      />
    </div>
  );
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (!apiResponse || apiResponse.success === false) {
    return <div className="screen-container">No Data</div>;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse(id, DUP_REFRESH_MS);

  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };