import React, {
  createContext,
  useContext,
  ComponentType,
  useState,
  useEffect,
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
 * What the "blink" element looks like is up to you--define styles as
 * appropriate on the "screen-container-blink" class.
 */

interface BlinkConfig {
  intervalMs: number;
  durationMs: number;
}

const defaultBlinkConfig = null;

const BlinkConfigContext = createContext<BlinkConfig | null>(
  defaultBlinkConfig
);

interface ScreenLayoutProps {
  apiResponse: ApiResponse;
}

const ScreenLayout: ComponentType<ScreenLayoutProps> = ({ apiResponse }) => {
  const responseMapper = useContext(ResponseMapperContext);
  const blinkConfig = useContext(BlinkConfigContext);

  const [showBlink, setShowBlink] = useState(false);

  if (blinkConfig != null) {
    useEffect(() => {
      const interval = setInterval(() => {
        setShowBlink(true);

        setTimeout(() => {
          setShowBlink(false);
        }, blinkConfig.durationMs);
      }, blinkConfig.intervalMs);

      return () => {
        clearInterval(interval);
      };
    }, []);
  }

  return (
    <div className="screen-container">
      {apiResponse && <Widget data={responseMapper(apiResponse)} />}
      {showBlink && <div className="screen-container-blink" />}
    </div>
  );
};

const ScreenContainer = ({ id }) => {
  const apiResponse = useApiResponse({ id });
  return <ScreenLayout apiResponse={apiResponse} />;
};

export default ScreenContainer;
export { ResponseMapper, ResponseMapperContext };
export { BlinkConfig, BlinkConfigContext };
