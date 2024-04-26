import React from "react";
import { classWithModifier } from "Util/util";

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

type Props =
  | (TextDeparture & { type: "text" })
  | (MinutesDeparture & { type: "minutes" })
  | (TimestampDeparture & { type: "timestamp" });

interface TextDeparture {
  text: string;
}
interface MinutesDeparture {
  minutes: number;
}
interface TimestampDeparture {
  hour: number;
  minute: number;
}

const DepartureTime = ({ type, ...data }: Props) => {
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
