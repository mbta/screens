import React from "react";

interface Props {
  station_name: string;
  time: string;
}

const NormalHeader: React.ComponentType<Props> = ({
  station_name: stationName,
  time,
}) => {
  return (
    <div className="header-normal">
      <div className="header-normal__station-name">{stationName}</div>
      <div className="header-normal__time">{time}</div>
    </div>
  );
};

export default NormalHeader;
