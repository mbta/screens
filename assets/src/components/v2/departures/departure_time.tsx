import React, { ComponentType } from "react";
import { classWithModifier } from "Util/utils";

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

const TimestampDepartureTime = ({ hour, minute }) => {
  const zeroFilledMinute = minute < 10 ? "0" + minute : minute;
  const timestamp = `${hour}:${zeroFilledMinute}`;

  return <div className="departure-time__timestamp">{timestamp}</div>;
};

type DepartureTime =
  | (TextDeparture & { type: "text" })
  | (MinutesDeparture & { type: "minutes" })
  | (TimestampDeparture & { type: "timestamp" })
  // Note: `overnight` is only produced in the DUP code path, and so is only
  // supported in the DUP version of this component.
  | { type: "overnight" };

interface TextDeparture {
  text: string;
}
interface MinutesDeparture {
  minutes: number;
}
interface TimestampDeparture {
  hour: number;
  minute: number;
  // Note: `am_pm` fields are currently only supported by the DUP version of
  // this component, but are always present in departures serialization.
  am_pm: string;
  show_am_pm: boolean;
}

const DepartureTime: ComponentType<DepartureTime> = ({ type, ...data }) => {
  let inner;
  if (type === "text") {
    inner = <TextDepartureTime {...(data as TextDeparture)} />;
  } else if (type === "minutes") {
    inner = <MinutesDepartureTime {...(data as MinutesDeparture)} />;
  } else if (type === "timestamp") {
    inner = <TimestampDepartureTime {...(data as TimestampDeparture)} />;
  }

  return (
    <div className={classWithModifier("departure-time", type)}>{inner}</div>
  );
};

export default DepartureTime;
