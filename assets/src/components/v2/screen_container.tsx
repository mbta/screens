import React, {
  createContext,
  useContext,
  ComponentType,
  useState,
  useEffect,
  Fragment,
} from "react";
import useApiResponse, {
  ApiResponse,
  SimulationData,
  useDUPApiResponse,
} from "Hooks/v2/use_api_response";
import WidgetTreeErrorBoundary from "Components/v2/widget_tree_error_boundary";
import Widget, { WidgetData } from "Components/v2/widget";
import useAudioReadout from "Hooks/v2/use_audio_readout";
import { isDup } from "Util/outfront";
import { classWithModifier, getScreenSide } from "Util/utils";

type ResponseMapper = (apiResponse: ApiResponse) => WidgetData | SimulationData;

const defaultResponseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
    case "simulation_success":
      return apiResponse.data;
    case "disabled":
    case "failure":
      return { type: "no_data" };
    case "loading":
      return { type: "page_load_no_data" };
  }
};

const LOADING_LAYOUT = {
  full_screen: {
    type: "page_load_no_data",
  },
  type: "screen_takeover",
};

const ResponseMapperContext = createContext<ResponseMapper>(
  defaultResponseMapper,
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
  defaultBlinkConfig,
);

interface AudioConfig {
  intervalOffsetSeconds: number;
  readoutIntervalMinutes: number;
}

const defaultAudioConfig = null;

const AudioConfigContext = createContext<AudioConfig | null>(
  defaultAudioConfig,
);

const LastFetchContext = createContext<number | null>(null);

interface ScreenLayoutProps {
  apiResponse: ApiResponse;
  showBlink: boolean;
}

const ScreenLayout: ComponentType<ScreenLayoutProps> = ({
  apiResponse,
  showBlink,
}) => {
  const responseMapper = useContext(ResponseMapperContext);
  const ErrorBoundaryOrFragment = isDup() ? Fragment : WidgetTreeErrorBoundary;

  // We know this can only be `WidgetData` and not `SimulationData` here because
  // `ScreenPage` is only used in contexts where a "non-simulation" API response
  // will be received (and vice-versa for `SimulationScreenLayout`).
  // TODO: Refactor how this works so the cast isn't needed, since it suppresses
  // any real type errors we might have.
  const widgetData = responseMapper(apiResponse) as WidgetData;

  return (
    <div className={classWithModifier("screen-container", getScreenSide())}>
      <ErrorBoundaryOrFragment>
        {apiResponse && <Widget data={widgetData} />}
      </ErrorBoundaryOrFragment>
      {showBlink && <div className="screen-container-blink" />}
    </div>
  );
};

const getApiResponseHook = () => {
  if (isDup()) {
    return useDUPApiResponse;
  } else {
    return useApiResponse;
  }
};

interface ScreenContainerProps {
  id: string;
  queryParams?: Map<string, string>;
}

const ScreenContainer = ({ id, queryParams }: ScreenContainerProps) => {
  const blinkConfig = useContext(BlinkConfigContext);
  const audioConfig = useContext(AudioConfigContext);
  const [showBlink, setShowBlink] = useState(false);
  const { apiResponse, requestCount, lastSuccess } = getApiResponseHook()({
    id,
    queryParams,
  });

  useAudioReadout({ id, config: audioConfig });

  useEffect(() => {
    if (
      blinkConfig != null &&
      requestCount % blinkConfig.refreshesPerBlink == 0
    ) {
      setShowBlink(true);

      setTimeout(() => {
        setShowBlink(false);
      }, blinkConfig.durationMs);
    }
  }, [requestCount]);

  return (
    <LastFetchContext.Provider value={lastSuccess}>
      <ScreenLayout apiResponse={apiResponse} showBlink={showBlink} />
    </LastFetchContext.Provider>
  );
};

export default ScreenContainer;
export {
  ResponseMapper,
  ResponseMapperContext,
  defaultResponseMapper,
  LOADING_LAYOUT,
};
export { BlinkConfig, BlinkConfigContext };
export { AudioConfig, AudioConfigContext };
export { LastFetchContext };
