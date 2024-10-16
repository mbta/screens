import React from "react";
import { formatTimeString } from "Util/util";

interface HeaderProps {
  id: string;
  time: string;
}

const Header = ({ id, time }: HeaderProps) => {
  return (
    <div className="header">
      <span className="header__id">Elevator {id}</span>
      <span className="header__time">{formatTimeString(time)}</span>
    </div>
  );
};

const ElevatorClosures: React.ComponentType<Props> = ({ id, time }: Props) => {
  return (
    <div className="elevator-closures">
      <Header id={id} time={time} />
    </div>
  );
};

export default ElevatorClosures;
