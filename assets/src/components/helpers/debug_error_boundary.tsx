import React from "react";

interface State {
  hasError: boolean;
}

/**
 * Do not use this component on customer facing pages!
 * It's for debugging only--it renders text that riders shouldn't see when its
 * children fail to render, and logs error info to the console.
 *
 * Wraps children in an error boundary so that render failures in the children
 * don't cause the entire page to fail.
 */
class DebugErrorBoundary extends React.Component {
  public static getDerivedStateFromError(_error: Error) {
    return { hasError: true };
  }

  public state: State;

  constructor(props: object) {
    super(props);
    this.state = {
      hasError: false
    };
  }

  public componentDidCatch(error: Error, errorInfo: object) {
    // tslint:disable-next-line:no-console
    console.error(error, errorInfo);
  }

  public componentDidUpdate(_prevProps: object, prevState: State) {
    // try to recover when a re-render occurs
    if (prevState.hasError) {
      this.setState({ hasError: false });
    }
  }

  public render() {
    if (this.state.hasError) {
      return <h1>Something went wrong. Check console for error info.</h1>;
    }
    return this.props.children;
  }
}

export default DebugErrorBoundary;
