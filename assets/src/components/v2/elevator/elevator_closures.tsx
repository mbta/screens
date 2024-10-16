import React from "react";

interface Props {
  id: string;
}

const ElevatorClosures: React.ComponentType<Props> = ({ id }: Props) => {
  return (
    <div className="elevator-closures">
      <div className="header">
        <span>{id}</span>
      </div>
    </div>
  );
};

export default ElevatorClosures;
