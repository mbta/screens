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

const DepartureTime = ({ type, ...data }) => {
  let inner;
  if (type === "text") {
    inner = <TextDepartureTime {...data} />;
  } else if (type === "minutes") {
    inner = <MinutesDepartureTime {...data} />;
  } else if (type === "timestamp") {
    inner = <TimestampDepartureTime {...data} />;
  }

  return (
    <div className={classWithModifier("departure-time", type)}>{inner}</div>
  );
};

export default DepartureTime;
