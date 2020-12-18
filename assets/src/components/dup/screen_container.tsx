import React from "react";

import Header from "Components/dup/header";
import SectionList from "Components/dup/section_list";
import PartialAlerts from "Components/dup/partial_alert";

import useApiResponse from "Hooks/use_api_response";

import { formatTimeString, classWithModifier } from "Util/util";

const NoDataLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className={classWithModifier("screen-container", "no-data")}>
      <div className="no-data__body">
        <div className="no-data__icon-container">
          <img
            className="no-data__icon-image"
            src="/images/live-data-none.svg"
          />
        </div>
        <div className="no-data__message">
          Live updates are temporarily unavailable
        </div>
      </div>
      <div className="no-data__url">mbta.com/schedules</div>
    </div>
  );
};

const DisabledLayout = ({ apiResponse }): JSX.Element => {
  const currentTime = formatTimeString(apiResponse.current_time);

  return (
    <div className={classWithModifier("screen-container", "disabled")}>
      <div className="disabled__time">{currentTime}</div>
      <div className="disabled__logo-container">
        <img className="disabled__logo-image" src="/images/logo-white.svg" />
      </div>
      <div className="disabled__url">mbta.com</div>
    </div>
  );
};

const StaticImageLayout = ({ srcUrl }): JSX.Element => {
  return (
    <div className="screen-container">
      <img src={srcUrl} />
    </div>
  );
};

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
    return <NoDataLayout apiResponse={apiResponse} />;
  } else if (apiResponse.type === "disabled") {
    return <DisabledLayout apiResponse={apiResponse} />;
  } else if (apiResponse.type === "static_image") {
    return <StaticImageLayout srcUrl={apiResponse.image_url} />;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse({ id, rotationIndex: 0 });

  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
