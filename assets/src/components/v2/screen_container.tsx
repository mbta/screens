import React, { createContext, useContext, ComponentType } from "react";
import useApiResponse, { ApiResponse } from "Hooks/v2/use_api_response";
import Widget, { WidgetData } from "Components/v2/widget";

type ResponseMapper = (apiResponse: ApiResponse) => WidgetData;

const defaultResponseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
      return apiResponse.data;
    case "disabled":
    case "failure":
      return { type: "no_data" };
  }
};

const ResponseMapperContext = createContext<ResponseMapper>(
  defaultResponseMapper
);

interface ScreenLayoutProps {
  apiResponse: ApiResponse;
}

const ScreenLayout: ComponentType<ScreenLayoutProps> = ({ apiResponse }) => {
  const responseMapper = useContext(ResponseMapperContext);

  return (
    <div className="screen-container">
      {apiResponse && <Widget data={responseMapper(apiResponse)} />}
    </div>
  );
};

const ScreenContainer = ({ id }) => {
  const apiResponse = useApiResponse({ id });
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ResponseMapper, ResponseMapperContext };
