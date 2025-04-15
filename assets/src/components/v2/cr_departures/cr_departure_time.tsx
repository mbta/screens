import moment from "moment";
import React from "react";
import { TimeRepresentation } from "Util/time_representation";
import LiveDataSvg from "Images/live-data-small.svg";

const baseDepartureTime = (time: TimeRepresentation): JSX.Element | null => {
  if (time.type === "text") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__text">{time.text}</span>
      </div>
    );
  } else if (time.type === "minutes") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__minutes">{time.minutes}</span>
        <span className="base-departure-time__minutes-label">m</span>
      </div>
    );
  } else if (time.type === "timestamp") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__timestamp">{time.timestamp}</span>
      </div>
    );
  } else {
    return null;
  }
};

interface CRDepartureTimeProps {
  departureType: "schedule" | "prediction";
  time: string | TimeRepresentation;
  isDelayed: boolean;
}

const CRDepartureTime = ({
  departureType,
  time,
  isDelayed,
}: CRDepartureTimeProps): JSX.Element => {
  const formattedTime = moment(time as string).format("h:mm");

  if (departureType === "schedule") {
    return (
      <div className="cr-departure-time">
        <div
          className={`cr-departure-time__prediction ${isDelayed ? "delayed" : ""}`}
        >
          {formattedTime}
        </div>
        <div className="cr-departure-time__subtext">
          {isDelayed ? "Delayed" : "Scheduled"}
        </div>
      </div>
    );
  }

  const predictionTime =
    typeof time === "string" ? (
      <span className="base-departure-time" style={{ display: "inline-block" }}>
        {formattedTime}
      </span>
    ) : (
      <span style={{ display: "inline-block" }}>{baseDepartureTime(time)}</span>
    );

  return (
    <div className="cr-departure-time">
      {predictionTime}
      <span style={{ display: "inline-block", marginLeft: "19px" }}>
        <LiveDataSvg
          color="black"
          width="36"
          height="36"
          viewBox="0 0 32 32"
          className="cr-departure-time__live-data-icon"
        />
      </span>
    </div>
  );
};

export default CRDepartureTime;
