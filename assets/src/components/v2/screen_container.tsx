import React from "react";
import useApiResponse from "Hooks/v2/use_api_response";
import Widget from "Components/v2/widget";

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
