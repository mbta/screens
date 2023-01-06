import React, { ErrorInfo, ReactElement } from "react";
import { RouteComponentProps, withRouter } from "react-router-dom";
interface ExceptionCatcherState {
  hasError: boolean;
  errorMessage?: Error;
}
interface ExceptionCatcherProps {
  children: ReactElement;
}
class ExceptionCatcher extends React.Component<
  ExceptionCatcherProps & RouteComponentProps<any>,
  ExceptionCatcherState
> {
  constructor(props: ExceptionCatcherProps & RouteComponentProps<any>) {
    super(props);
  }

  // Make an API call to log the error before rethrowing.
  async componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    const csrfToken = document.head.querySelector(
      "[name~=csrf-token][content]"
    ).content;
    await fetch("/v2/api/screen/log_frontend_error", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-csrf-token": csrfToken,
      },
      credentials: "include",
      body: JSON.stringify({
        id: this.props.match.params.id,
        stacktrace: errorInfo.componentStack,
        errorMessage: error.message,
      }),
    });

    throw error;
  }

  render(): React.ReactNode {
    return this.props.children;
  }
}

export default withRouter(ExceptionCatcher);
