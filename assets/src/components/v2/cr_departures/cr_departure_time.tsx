import BaseDepartureTime from "Components/eink/base_departure_time";
import moment from "moment";
import React from "react";
import { TimeRepresentation } from "Util/time_representation";
import LiveDataSvg from '../../../../static/images/svgr_bundled/live-data-small.svg'

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
      <span className="base-departure-time" style={{ display: "inline-block" }}>{formattedTime}</span>
    ) : (
      <span style={{ display: "inline-block" }}>
        <BaseDepartureTime time={time as TimeRepresentation} hideAmPm />
      </span>
    );

  return (
    <div className="cr-departure-time">
      {predictionTime}
      <span style={{ display: "inline-block", marginLeft: "19px" }}>
        <LiveDataSvg color="black" width="36" height="36" viewBox="0 0 32 32" className="cr-departure-time__live-data-icon" />
      </span>
    </div>
  );
};

export default CRDepartureTime;
