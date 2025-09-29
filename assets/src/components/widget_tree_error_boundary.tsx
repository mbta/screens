import {
  type ComponentType,
  type PropsWithChildren,
  Component,
  ErrorInfo,
  useContext,
} from "react";
import { useLocation, useNavigate, useParams } from "react-router";
import { captureReactException } from "@sentry/react";

import getCsrfToken from "Util/csrf";
import { getDataset } from "Util/dataset";
import { isRealScreen } from "Util/utils";
import {
  ResponseMapperContext,
  LastFetchContext,
} from "Components/screen_container";
import Widget, { WidgetData } from "Components/widget";

// The component uses the `match` prop supplied by withRouter for error logging.
interface Props extends PropsWithChildren {
  // Whether to show the fallback component when an error is caught.
  // If false, the component will render nothing on error.
  // Defaults to true.
  showFallbackOnError?: boolean;
  // Supplied by withLastFetchContext
  lastFetch: number | null;
  match?: { params?: { id?: string } };
}

interface State {
  // Did we catch an error while rendering the most recent data?
  hasError: boolean;
  // Lets us hold onto the previous value of the `lastFetch` prop.
  prevLastFetch: number | null;
}

/**
 * A component that catches an error thrown while rendering any of its
 * descendents, logs the error via the backend, and then optionally
 * displays the app's no-data state.
 * (If no error is thrown during render, this component just renders its children normally.)
 *
 * PLEASE NOTE ============================================================
 * In order to know what fallback content to show, this component must have
 * access to the `ResponseMapperContext` context.
 * ========================================================================
 *
 * Whenever we receive new data from the backend, this component gives the
 * normal render another try, even if an error was previously thrown.
 */
class WidgetTreeErrorBoundary extends Component<Props, State> {
  state = { hasError: false, prevLastFetch: this.props.lastFetch };

  // When an error is thrown during render, log it.
  // Repeat logs have a cooldown of 10 minutes, to avoid overloading quotas.
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    if (LogTimeRecorder.noErrorsOfTypeInLast10Minutes(error)) {
      this.doLog(error, errorInfo);
    }
  }

  doLog(error: Error, errorInfo: ErrorInfo) {
    LogTimeRecorder.recordLogForError(error);

    if (!isRealScreen()) {
      // We're running in someone's browser. Log to the console so that the error isn't silently discarded.
      console.error(
        "WidgetTreeErrorBoundary caught an error during render",
        error,
        errorInfo,
      );
      return;
    }

    if (!getDataset().sentry) {
      // Log via the server. (to Splunk, at time of writing.)
      fetch("/v2/api/logging/log_frontend_error", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-csrf-token": getCsrfToken(),
        },
        credentials: "include",
        body: JSON.stringify({
          id: this.props.match?.params?.id,
          stacktrace: errorInfo.componentStack,
          errorMessage: error.message,
        }),
      });
    } else {
      // Log directly to Sentry.
      captureReactException(error, errorInfo);
    }
  }

  // Whenever lastFetch changes, it means we received new data from the server.
  // Reset the state so we can try the normal render again with the new data.
  static getDerivedStateFromProps(props: Props, state: State) {
    if (props.lastFetch !== state.prevLastFetch) {
      return { hasError: false, prevLastFetch: props.lastFetch };
    }
    return null;
  }

  // When an error is thrown during render, we update the state accordingly.
  static getDerivedStateFromError(_error: any) {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      // We've caught an error.
      const { showFallbackOnError = true } = this.props;

      return showFallbackOnError ? <FallbackLayout /> : null;
    } else {
      // No error was thrown in the previous render.
      // Try rendering normally.
      return this.props.children;
    }
  }
}

/**
 * A fallback component to use when the normal render throws an error.
 *
 * The component renders whatever layout is configured for the screen type
 * when it fails to fetch API data.
 */
const FallbackLayout: ComponentType = () => {
  const responseMapper = useContext(ResponseMapperContext);

  return <Widget data={responseMapper({ state: "failure" }) as WidgetData} />;
};

const MINUTE_IN_MS = 60 * 1000;

/**
 * Utility object to track the last time we logged an error.
 */
const LogTimeRecorder = (() => {
  const logTimestampByError: { [errorKey: string]: number } = {};

  const getKey = (error: Error) => error.name + error.message;

  const recordLogForError = (error: Error) => {
    logTimestampByError[getKey(error)] = Date.now();
  };

  const noErrorsOfTypeInLast10Minutes = (error: Error) => {
    const now = Date.now();
    const lastLog = logTimestampByError[getKey(error)] ?? 0;

    return now - lastLog > 10 * MINUTE_IN_MS;
  };

  return { recordLogForError, noErrorsOfTypeInLast10Minutes };
})();

// It's necessary to get the context separately and pass it to the component
// as a prop because we need this value in getDerivedStateFromProps, which
// does not receive context as an argument.
const WrappedWithLastFetch: ComponentType<Omit<Props, "lastFetch">> = (
  props,
) => {
  const lastFetch = useContext(LastFetchContext);

  return <WidgetTreeErrorBoundary {...props} lastFetch={lastFetch} />;
};

// https://reactrouter.com/en/main/start/faq#what-happened-to-withrouter-i-need-it
function withRouter<ComponentProps>(Component: ComponentType<ComponentProps>) {
  function ComponentWithRouterProp(props: ComponentProps) {
    const location = useLocation();
    const navigate = useNavigate();
    const params = useParams();

    return <Component {...props} router={{ location, navigate, params }} />;
  }

  return ComponentWithRouterProp;
}

export default withRouter(WrappedWithLastFetch);
