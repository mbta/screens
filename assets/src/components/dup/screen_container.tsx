import React from "react";

import Header from "Components/dup/header";
import SectionList from "Components/dup/section_list";
import PartialAlerts from "Components/dup/partial_alert";

import useApiResponse from "Hooks/use_api_response";

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
      {apiResponse.alerts?.length > 0 && (
        <PartialAlerts alerts={apiResponse.alerts} />
      )}
    </div>
  );
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (!apiResponse || apiResponse.success === false) {
    return <div className="screen-container">No Data</div>;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id, rotationIndex }): JSX.Element => {
  const apiResponse = useApiResponse({ id, rotationIndex });

  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
