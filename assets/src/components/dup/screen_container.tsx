import React from "react";

import Header from "Components/dup/header";
import SectionList from "Components/dup/section_list";
import PartialAlerts from "Components/dup/partial_alert";
import FreeText from "Components/dup/free_text";

import useApiResponse from "Hooks/use_api_response";
import useOutfrontStation from "Hooks/use_outfront_station";
import useCurrentPage from "Hooks/use_current_dup_page";

import { formatTimeString, classWithModifier, imagePath } from "Util/util";

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

// Fix station name tags without rider-facing names
const REPLACEMENTS = {
  WTC: "World Trade Center",
  Malden: "Malden Center",
};

const NoDataLayout = ({ code }: { code?: string }): JSX.Element => {
  let stationName = useOutfrontStation() || "Transit information";
  stationName = REPLACEMENTS[stationName] || stationName;

  return (
    <div className={classWithModifier("screen-container", "no-data")}>
      <Header text={stationName} code={code} />
      <div className="no-data__body">
        <div className="no-data__icon-container">
          <img
            className="no-data__icon-image"
            src={imagePath("live-data-none.svg")}
          />
        </div>
        <div className="no-data__message">
          Live updates are temporarily unavailable
        </div>
      </div>
      <div className="no-data__link">
        <div className="no-data__link-arrow">
          <LinkArrow width="375" color="#a2a3a3" />
        </div>
        <div className="no-data__link-text">mbta.com/schedules</div>
      </div>
    </div>
  );
};

const DisabledLayout = ({ apiResponse }): JSX.Element => {
  const currentTime = formatTimeString(apiResponse.current_time);

  return (
    <div className={classWithModifier("screen-container", "disabled")}>
      <div className="disabled__time">{currentTime}</div>
      <div className="disabled__logo-container">
        <img
          className="disabled__logo-image"
          src={imagePath("logo-white.svg")}
        />
      </div>
      <div className="disabled__link">
        <div className="disabled__link-arrow">
          <LinkArrow width="576" color="#64696e" />
        </div>
        <div className="disabled__link-text">mbta.com</div>
      </div>
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

const DefaultScreenLayout = ({ apiResponse, currentPage }): JSX.Element => {
  return (
    <div className="screen-container">
      <Header
        text={apiResponse.header}
        currentTimeString={apiResponse.current_time}
      />
      <SectionList
        sections={apiResponse.sections}
        currentTimeString={apiResponse.current_time}
        currentPage={currentPage}
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
  const currentPage = useCurrentPage();

  if (!apiResponse || apiResponse.success === false) {
    return <NoDataLayout code="1" />;
  }

  switch (apiResponse.type) {
    case "disabled":
      return <DisabledLayout apiResponse={apiResponse} />;
    case "static_image":
      return <StaticImageLayout srcUrl={apiResponse.image_url} />;
    case "full_screen_alert":
      return <FullScreenAlertLayout apiResponse={apiResponse} />;
    default:
      return (
        <DefaultScreenLayout
          apiResponse={apiResponse}
          currentPage={currentPage}
        />
      );
  }
};

const ScreenContainer = ({ id, rotationIndex, refreshMs }): JSX.Element => {
  const apiResponse = useApiResponse({ id, rotationIndex, refreshMs });

  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { NoDataLayout, ScreenLayout };
