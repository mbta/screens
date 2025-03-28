import React, { ComponentType } from "react";
import { classWithModifier, imagePath } from "Util/utils";

import type DepartureTimeBase from "Components/v2/departures/departure_time";

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

const TimestampDepartureTime = ({ hour, minute, am_pm, show_am_pm }) => {
  const zeroFilledMinute = minute < 10 ? "0" + minute : minute;
  const timestamp = `${hour}:${zeroFilledMinute}`;

  return (
    <div className="departure-time__timestamp">
      <span className="departure-time__time">{timestamp}</span>
      {show_am_pm && <span className="departure-time__ampm">{am_pm}</span>}
    </div>
  );
};

interface Props {
  time: DepartureTimeBase;
  scheduled_time?: DepartureTimeBase;
}

const DepartureTime: ComponentType<Props> = ({ time }) => {
  let predictedTime;
  if (time.type === "overnight") {
    predictedTime = (
      <img className="departure-time__moon-icon" src={imagePath(`moon.svg`)} />
    );
  } else if (time.type === "text") {
    predictedTime = <TextDepartureTime {...time} />;
  } else if (time.type === "minutes") {
    predictedTime = <MinutesDepartureTime {...time} />;
  } else if (time.type === "timestamp") {
    predictedTime = <TimestampDepartureTime {...time} />;
  }

  return (
    <div className={classWithModifier("departure-time", time.type)}>
      {predictedTime}
    </div>
  );
};

export default DepartureTime;
