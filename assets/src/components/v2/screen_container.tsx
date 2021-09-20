import React, {
  createContext,
  useContext,
  ComponentType,
  useState,
} from "react";
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

/* "Blink" info
 *
 * Some screens need to have their pixels "flipped" every so often in order to
 * reduce burn-in. The "blink" context set on a per-screen-type basis
 * dictates whether, how frequently, and for what duration this occurs.
 *
 * Blink frequency is defined relative to screen data refreshes by
 * `refreshesPerBlink`, in order to have blinks sync up with data refreshes.
 * E.g. if a given app's refresh rate is 20 sec and `refreshesPerBlink` is 15,
 * a blink will occur every 20 sec * 15 = 300 sec = 5 min.
 *
 * What the "blink" element looks like is up to you--define styles as
 * appropriate on the "screen-container-blink" class.
 */

interface BlinkConfig {
  refreshesPerBlink: number;
  durationMs: number;
}

const defaultBlinkConfig = null;

const BlinkConfigContext = createContext<BlinkConfig | null>(
  defaultBlinkConfig
);

interface ScreenLayoutProps {
  apiResponse: ApiResponse;
  showBlink: boolean;
}

const ScreenLayout: ComponentType<ScreenLayoutProps> = ({
  apiResponse,
  showBlink,
}) => {
  const responseMapper = useContext(ResponseMapperContext);

  return (
    <div className="screen-container">
      {apiResponse && <Widget data={responseMapper(apiResponse)} />}
      {showBlink && <div className="screen-container-blink" />}
    </div>
  );
};

const ScreenContainer = ({ id }: { id: string }) => {
  const blinkConfig = useContext(BlinkConfigContext);
  const [showBlink, setShowBlink] = useState(false);

  const apiResponse = useApiResponse({ id, blinkConfig, setShowBlink });

  return <ScreenLayout apiResponse={apiResponse} showBlink={showBlink} />;
};

export default ScreenContainer;
export { ResponseMapper, ResponseMapperContext };
export { BlinkConfig, BlinkConfigContext };
