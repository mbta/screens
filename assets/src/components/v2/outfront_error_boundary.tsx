import React, { ErrorInfo, useContext } from "react";
import getCsrfToken from "Util/csrf";
import { ResponseMapperContext } from "Components/v2/screen_container";
import Widget, { WidgetData } from "Components/v2/widget";
import { getPlayerName } from "Util/outfront";
import { getOutfrontAbsolutePath } from "Hooks/v2/use_api_response";

// A basic error boundary that wraps the render tree for Outfront clients.

// This gives us a chance to catch and log any unexpected errors that happen
// in MRAID logic that we depend on but can't directly see or fix.

// Displays the app's `FAILURE_LAYOUT` if an error is caught.

interface Props { }

interface State {
  hasError: boolean;
}

class OutfrontErrorBoundary extends React.Component<Props, State> {
  state = { hasError: false };

  // When an error is thrown during render, log it.
  // Repeat logs have a cooldown of 10 minutes, to avoid overloading quotas.
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.doLog(error, errorInfo);
  }

  doLog(error: Error, errorInfo: ErrorInfo) {
    // Log via the server. (to Splunk, at time of writing.)
    fetch(`${getOutfrontAbsolutePath()}/v2/api/logging/log_frontend_error`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        id: this.tryGetPlayerName(),
        stacktrace: errorInfo.componentStack,
        errorMessage: error.message,
      }),
    });
  }

  tryGetPlayerName() {
    try {
      return `ofm-player--${getPlayerName()}`;
    } catch (err) {
      return "no-player-name-because-getPlayerName-failed";
    }
  }

  // When an error is thrown during render, we update the state accordingly.
  static getDerivedStateFromError(_error: any) {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      return <FallbackLayout />;
    } else {
      return this.props.children;
    }
  }
};

/**
 * A fallback component to use when the normal render throws an error.
 *
 * The component renders whatever layout is configured for the screen type
 * when it fails to fetch API data.
 */
const FallbackLayout: React.ComponentType = () => {
  const responseMapper = useContext(ResponseMapperContext);

  return <Widget data={responseMapper({ state: "failure" }) as WidgetData} />;
};

export default OutfrontErrorBoundary;
