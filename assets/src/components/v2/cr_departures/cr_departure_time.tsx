import BaseDepartureTime from "Components/eink/base_departure_time";
import moment from "moment";
import React from "react";
import { TimeRepresentation } from "Util/time_representation";
import { classWithModifier } from "Util/util";
import LiveData from "Components/v2/bundled_svg/live_data";

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
          className={`cr-departure-time__text ${isDelayed ? "delayed" : ""}`}
        >
          {formattedTime}
        </div>
        <div
          className={classWithModifier("cr-departure-time__subtext", "english")}
        >
          {isDelayed ? "Delayed" : "Scheduled"}
        </div>
        <div
          className={classWithModifier("cr-departure-time__subtext", "spanish")}
        >
          {isDelayed ? "Atrasado" : "Programada"}
        </div>
      </div>
    );
  }

  const predictionTime =
    typeof time === "string" ? (
      <span style={{ display: "inline-block" }}>{formattedTime}</span>
    ) : (
      <span style={{ display: "inline-block" }}>
        <BaseDepartureTime time={time as TimeRepresentation} hideAmPm />
      </span>
    );

  return (
    <div className="cr-departure-time">
      {predictionTime}
      <span style={{ display: "inline-block", marginLeft: "19px" }}>
        <LiveData
          className="cr-departure-time__live-data-icon"
          colorHex="#737373"
        />
      </span>
    </div>
  );
};

export default CRDepartureTime;
