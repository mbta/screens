import React, { ComponentType } from "react";
import { classWithModifier } from "Util/utils";
import type DepartureTimeBase from "Components/v2/departures/departure_time";

interface TextDeparture {
  text: string;
}
interface MinutesDeparture {
  minutes: number;
}

type DepartureTime =
  | (TextDeparture & { type: "text" })
  | (MinutesDeparture & { type: "minutes" })

const TextDepartureTime = ({ text }) => {
  return <div className="departure-time__text">{text}</div>;
};

const MinutesDepartureTime = ({ minutes }) => {
  return (
    <>
      <div className="departure-time__minutes">{minutes}</div>
      <div className="departure-time__minutes-label">m</div>
    </>
  );
};
interface Props {
  time: DepartureTimeBase;
  scheduled_time?: DepartureTimeBase;
}

const DepartureTime: ComponentType<Props> = ({ time }) => {
  let predictedTime;
   if (time.type === "text") {
    predictedTime = <TextDepartureTime {...time} />;
  } else if (time.type === "minutes") {
    predictedTime = <MinutesDepartureTime {...time} />;
  }
  return (
    <div className={classWithModifier("departure-time", time.type)}>
      {predictedTime}
    </div>
  );
};

export default DepartureTime;
