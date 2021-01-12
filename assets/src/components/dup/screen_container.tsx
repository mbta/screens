import React from "react";

import Header from "Components/dup/header";
import SectionList from "Components/dup/section_list";
import PartialAlerts from "Components/dup/partial_alert";
import FreeText from "Components/dup/free_text";

import useApiResponse from "Hooks/use_api_response";

const LinkArrow = ({ width, color }) => {
  const height = 40;
  const stroke = 8;
  const headWidth = 40;

  const d = [
    "M",
    stroke / 2,
    height / 2,
    "L",
    width - headWidth,
    height / 2,
    "L",
    width - headWidth,
    stroke / 2,
    "L",
    width - stroke / 2,
    height / 2,
    "L",
    width - headWidth,
    height - stroke / 2,
    "L",
    width - headWidth,
    height / 2,
    "Z",
  ].join(" ");

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={`0 0 ${width} ${height}`}
      width={`${width}px`}
      height={`${height}px`}
      version="1.1"
    >
      <path
        stroke={color}
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeLinejoin="round"
        fill={color}
        d={d}
      />
    </svg>
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

const FullScreenAlertLayout = ({ apiResponse }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header
        text={apiResponse.header}
        color={apiResponse.color}
        pattern={apiResponse.pattern}
        currentTimeString={apiResponse.current_time}
      />
      <div className="full-screen-alert__body">
        <div className="full-screen-alert-text">
          <FreeText lines={[apiResponse.issue, apiResponse.remedy]} />
        </div>
        <div className="full-screen-alert__link">
          <div className="full-screen-alert__link-arrow">
            <LinkArrow width="628" color="#64696e" />
          </div>
          <div className="full-screen-alert__link-text">mbta.com/alerts</div>
        </div>
      </div>
    </div>
  );
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (!apiResponse || apiResponse.success === false) {
    return <div className="screen-container">No Data</div>;
  }

  switch (apiResponse.type) {
    case "full_screen_alert":
      return <FullScreenAlertLayout apiResponse={apiResponse} />;
    case "departures":
      return <DefaultScreenLayout apiResponse={apiResponse} />;
  }
};

const ScreenContainer = ({ id }): JSX.Element => {
  const apiResponse = useApiResponse({ id, rotationIndex: 0 });

  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
