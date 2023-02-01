import React from "react";
import { classWithModifier, classWithModifiers } from "Util/util";

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

const DepartureTime = ({ scheduled_time, time, currentPage }) => {
  let predictedTime;

  if (time.type === "text") {
    predictedTime = <TextDepartureTime {...time} />;
  } else if (time.type === "minutes") {
    predictedTime = <MinutesDepartureTime {...time} />;
  } else if (time.type === "timestamp") {
    predictedTime = <TimestampDepartureTime {...time} />;
  }

  if (!scheduled_time) {
    return (
      <div className={classWithModifier("departure-time", time.type)}>
        {predictedTime}
      </div>
    );
  }

  let scheduledTime;

  if (time.type === "text") {
    scheduledTime = <TextDepartureTime {...scheduled_time} />;
  } else if (time.type === "minutes") {
    scheduledTime = <MinutesDepartureTime {...scheduled_time} />;
  } else if (time.type === "timestamp") {
    scheduledTime = <TimestampDepartureTime {...scheduled_time} />;
  }
  if (currentPage === 0) {
    return (
      <div className={classWithModifier("departure-time", time.type)}>
        {predictedTime}
      </div>
    );
  } else {
    return (
      <div
        className={classWithModifiers("departure-time", [
          time.type,
          "disabled",
        ])}
      >
        {scheduledTime}
      </div>
    );
  }
};

export default DepartureTime;
