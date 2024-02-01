import React from "react";

import Header from "Components/solari/header";
import SectionListContainer from "Components/solari/section_list_container";
import Psa from "Components/solari/psa";

import { classWithModifier, imagePath } from "Util/util";

import useApiResponse from "Hooks/use_api_response";

import { SOLARI_REFRESH_MS } from "Constants";
import { useLocation } from "react-router-dom";
import LoadingLayout from "Components/solari/loading_layout";

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
        stationName={apiResponse.station_name}
      />
      {apiResponse.psa_url && (
        <Psa
          psaUrl={apiResponse.psa_url}
          currentTimeString={apiResponse.current_time}
        />
      )}
    </div>
  );
};

const FullScreenImageLayout = ({ srcPath }): JSX.Element => {
  return (
    <div className="screen-container">
      <img src={srcPath} />
    </div>
  );
};

const NoConnectionScreenLayout = (): JSX.Element => {
  const srcPath = imagePath("solari-no-data.png");
  return <FullScreenImageLayout srcPath={srcPath} />;
};

const TakeoverScreenLayout = ({ apiResponse }): JSX.Element => {
  return <FullScreenImageLayout srcPath={apiResponse.psa_url} />;
};

const LoadingScreenLayout = (): JSX.Element => {
  return <LoadingLayout />;
};

const ScreenLayout = ({ apiResponse }): JSX.Element => {
  if (!apiResponse || apiResponse.success === false) {
    return <NoConnectionScreenLayout />;
  }

  if (apiResponse.type === "loading") {
    return <LoadingScreenLayout />;
  }

  if (apiResponse.psa_type === "takeover") {
    return <TakeoverScreenLayout apiResponse={apiResponse} />;
  }

  return <DefaultScreenLayout apiResponse={apiResponse} />;
};

const ScreenContainer = ({ id }): JSX.Element => {
  const query = new URLSearchParams(useLocation().search);
  const datetime = query.get("datetime");

  const apiResponse = useApiResponse({
    id,
    datetime,
    refreshMs: SOLARI_REFRESH_MS,
    withWatchdog: true,
  });
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ScreenLayout };
