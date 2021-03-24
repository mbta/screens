import React from "react";
import useApiResponse from "Hooks/v2/use_api_response";

const ScreenLayout = ({ apiResponse, WidgetComponent }) => {
  return (
    <div className="screen-container">
      {apiResponse && <WidgetComponent data={apiResponse} />}
    </div>
  );
};

const ScreenContainer = ({ id, WidgetComponent }) => {
  const apiResponse = useApiResponse({ id });
  return (
    <ScreenLayout apiResponse={apiResponse} WidgetComponent={WidgetComponent} />
  );
};

export default ScreenContainer;
