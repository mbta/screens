import BaseDepartureTime from "Components/eink/base_departure_time";
import moment from "moment";
import React from "react";
import { TimeRepresentation } from "Util/time_representation";
import { classWithModifier } from "Util/util";

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
        <div className="cr-departure-time__text">{formattedTime}</div>
        <div
          className={classWithModifier("cr-departure-time__subtext", "english")}
        >
          Scheduled
        </div>
        <div
          className={classWithModifier("cr-departure-time__subtext", "spanish")}
        >
          Programada
        </div>
      </div>
    );
  }

  if (typeof time === "string" && isDelayed) {
    return (
      <div className="cr-departure-time">
        <div className="cr-departure-time__text delayed">{formattedTime}</div>
        <div
          className={classWithModifier("cr-departure-time__subtext", "english")}
        >
          Delayed
        </div>
        <div
          className={classWithModifier("cr-departure-time__subtext", "spanish")}
        >
          Atrasado
        </div>
      </div>
    );
  }

  return (
    <div className="cr-departure-time">
      <BaseDepartureTime time={time as TimeRepresentation} hideAmPm />
    </div>
  );
};

export default CRDepartureTime;
