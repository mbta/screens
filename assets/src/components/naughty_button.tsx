import React from "react";

interface Props {
  appID: string;
}

const NaughtyButton: React.ComponentType<Props> = ({ appID }) => {
  const handleClick = () => {
    throw new Error(`Testing Sentry logging on app: ${appID}`);
  };

  return (
    <button onClick={handleClick} style={{ zIndex: 99999, position: "absolute", left: "100px", top: "100px" }}>Press to throw an error</button>
  );
};

export default NaughtyButton;
