import React from "react";
import Widget from "Components/v2/widget";
import useApiResponse from "Hooks/v2/use_api_response";

const ScreenLayout = ({ apiResponse }) => {
  return (
    <div className="screen-container">
      {apiResponse && <Widget data={apiResponse} />}
    </div>
  );
};

const ScreenContainer = ({ id }) => {
  const apiResponse = useApiResponse({ id });
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
