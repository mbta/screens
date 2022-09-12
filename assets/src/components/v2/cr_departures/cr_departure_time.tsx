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
      <span style={{ display: "inline-block" }}>
        <BaseDepartureTime time={time as TimeRepresentation} hideAmPm />
      </span>
      <span style={{ display: "inline-block", marginLeft: "19px" }}>
        <LiveData colorHex="#737373" />
      </span>
    </div>
  );
};

export default CRDepartureTime;
