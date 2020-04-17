import React from "react";

type State = {hasError: boolean};

/**
 * Do not use this component on customer facing pages!
 * It's for debugging only--it renders text that riders shouldn't see when its
 * children fail to render.
 *
 * Wraps children in an error boundary so that render failures in the children
 * don't cause the entire page to fail.
 */
class DebugErrorBoundary extends React.Component {
  state: State;

  constructor(props: object) {
    super(props);
    this.state = {
      hasError: false
    };
  }

  static getDerivedStateFromError(_error: Error) {
    return {hasError: true};
  }

  componentDidCatch(error: Error, errorInfo: object) {
    console.error(error, errorInfo);
  }

  componentDidUpdate(_prevProps: object, prevState: State) {
    // try to recover when a re-render occurs
    if (prevState.hasError) {
      this.setState({hasError: false});
    }
  }

  render() {
    if (this.state.hasError) {
      return <h1>Something went wrong. Check console for error info.</h1>;
    }
    return this.props.children;
  }
}

export default DebugErrorBoundary;
