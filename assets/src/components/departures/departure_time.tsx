import { ComponentType, useEffect, useState } from "react";

import { useCurrentPage } from "Context/dup_page";
import MoonIcon from "Images/moon.svg";
import LiveDataSvg from "Images/live-data-small.svg";
import { classWithModifier, classWithModifiers } from "Util/utils";

type DepartureTime =
  | { type: "text"; text: string }
  | { type: "minutes"; minutes: number }
  | { type: "timestamp"; hour: number; minute: number }
  | { type: "status"; pages: string[] }
  | { type: "overnight" };

interface DepartureTimePartProps {
  time: DepartureTime;
  timeInEpoch: number;
  currentPage: number;
}

/**
 * Given two dates, compute the difference in seconds between `departureTimeSeconds`
 * and `currentDateTime`.
 *
 * If the difference between the two values in minutes results in a float,
 * round the result (rounding method is considered an implementation detail).
 * This function will always return a value of 1 or greater - the system relies
 * on the backend to provide the appropriate text ("ARR", "BRD", etc.) in lieu
 * of showing '0 min'.
 *
 * @param departureTimeSeconds A datetime provided by the backend, representing
 * the departure time of a route at a stop.
 * @param currentDateTime The current datetime of the browser
 */
const adjustMinute = (
  departureTimeSeconds: Date,
  currentDateTime: Date,
): number => {
  const timeDifferenceMin =
    departureTimeSeconds.getTime() - currentDateTime.getTime() / 1000;
  const timeDifferenceSeconds = Math.floor(timeDifferenceMin / 60);
  return Math.max(timeDifferenceSeconds, 1);
};

const DepartureTimePart: ComponentType<DepartureTimePartProps> = ({
  time,
  timeInEpoch,
  currentPage,
}) => {
  const [currentDateTime, setCurrentDateTime] = useState(new Date());
  useEffect(() => {
    const intervalTimer = setInterval(() => {
      setCurrentDateTime(new Date());
    }, 1000);

    return () => clearInterval(intervalTimer);
  }, []);
  switch (time.type) {
    case "text":
      return <div className="departure-time__text">{time.text}</div>;

    case "minutes":
      return (
        <>
          <div className="departure-time__minutes">
            {adjustMinute(new Date(timeInEpoch), currentDateTime)}
          </div>
          <div className="departure-time__minutes-label">m</div>
        </>
      );

    case "timestamp": {
      const paddedMinute = time.minute < 10 ? "0" + time.minute : time.minute;
      const timestamp = `${time.hour}:${paddedMinute}`;

      return <span className="departure-time__timestamp">{timestamp}</span>;
    }

    case "status": {
      const pages = time.pages;
      if (pages.length === 1) {
        return <div className="departure-time__status">{pages[0]}</div>;
      } else {
        return (
          <div className="departure-time__status">{pages[currentPage]}</div>
        );
      }
    }

    case "overnight":
      return <MoonIcon width={128} height={128} color="black" />;
  }
};

interface Props {
  time?: DepartureTime;
  time_in_epoch: number;
  scheduled_time?: DepartureTime;
  is_live: boolean;
}

const DepartureTime: ComponentType<Props> = ({
  time,
  time_in_epoch: timeInEpoch,
  scheduled_time,
  is_live: isLive,
}) => {
  const currentPage = useCurrentPage();
  if (time && (currentPage === 0 || !scheduled_time)) {
    return (
      <div className={classWithModifier("departure-time", time.type)}>
        {showLiveIcon(isLive, time.type, currentPage) && (
          <LiveDataSvg
            color="gray"
            width="36"
            height="36"
            viewBox="0 0 32 32"
            className="departure-time__live-icon"
          />
        )}
        <DepartureTimePart
          currentPage={currentPage}
          time={time}
          timeInEpoch={timeInEpoch}
        />
      </div>
    );
  } else if (scheduled_time && (currentPage === 1 || !time)) {
    return (
      <div
        className={classWithModifiers("departure-time", [
          scheduled_time.type,
          time ? "delayed" : "cancelled",
        ])}
      >
        <DepartureTimePart
          {...{
            time: scheduled_time,
            timeInEpoch: timeInEpoch,
            currentPage,
          }}
        />
      </div>
    );
  } else {
    throw new Error("DepartureTime has neither time nor scheduled_time");
  }
};

const showLiveIcon = (
  isLiveData: boolean,
  timeType: string,
  currentPage: number,
) => isLiveData && (currentPage === 0 || timeType !== "status");

export default DepartureTime;
