import type { ComponentType } from "react";
import { classWithModifier, classWithModifiers, imagePath } from "Util/utils";

import type DepartureTimeBase from "Components/departures/departure_time";

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

const StopsAwayDepartureTime = ({ prefix, suffix, currentPage }) => {
  // Show prefix ("Stopped") on page 0, suffix ("N stop(s) away") on page 1+
  const text = currentPage === 0 ? prefix : suffix;
  return <div className="departure-time__text">{text}</div>;
};

interface Props {
  time: DepartureTimeBase;
  scheduled_time?: DepartureTimeBase;
  currentPage: number;
}

const DepartureTime: ComponentType<Props> = ({
  scheduled_time,
  time,
  currentPage,
}) => {
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
  } else if (time.type === "stops_away") {
    predictedTime = (
      <StopsAwayDepartureTime {...time} currentPage={currentPage} />
    );
  }

  if (!scheduled_time) {
    return (
      <div className={classWithModifier("departure-time", time.type)}>
        {predictedTime}
      </div>
    );
  }

  let scheduledTime;

  if (scheduled_time.type === "text") {
    scheduledTime = <TextDepartureTime {...scheduled_time} />;
  } else if (scheduled_time.type === "minutes") {
    scheduledTime = <MinutesDepartureTime {...scheduled_time} />;
  } else if (scheduled_time.type === "timestamp") {
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
          scheduled_time.type,
          "disabled",
        ])}
      >
        {scheduledTime}
      </div>
    );
  }
};

export default DepartureTime;
