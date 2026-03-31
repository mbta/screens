import type { ComponentType } from "react";

import { useCurrentPage } from "Context/dup_page";
import MoonIcon from "Images/moon.svg";
import LiveDataSvg from "Images/live-data-small.svg";
import { classWithModifier, classWithModifiers } from "Util/utils";

type DepartureTime =
  | { type: "text"; text: string }
  | { type: "minutes"; minutes: number }
  | { type: "timestamp"; hour: number; minute: number; am_pm: string | null }
  | { type: "status"; pages: string[] }
  | { type: "overnight" };

interface DepartureTimePartProps {
  time: DepartureTime;
  currentPage: number;
}

const DepartureTimePart: ComponentType<DepartureTimePartProps> = ({
  time,
  currentPage,
}) => {
  switch (time.type) {
    case "text":
      return <div className="departure-time__text">{time.text}</div>;

    case "minutes":
      return (
        <>
          <div className="departure-time__minutes">{time.minutes}</div>
          <div className="departure-time__minutes-label">m</div>
        </>
      );

    case "timestamp": {
      const paddedMinute = time.minute < 10 ? "0" + time.minute : time.minute;
      const timestamp = `${time.hour}:${paddedMinute}`;

      return (
        <div className="departure-time__timestamp">
          <span className="departure-time__time">{timestamp}</span>
          {time.am_pm && (
            <span className="departure-time__ampm">{time.am_pm}</span>
          )}
        </div>
      );
    }

    case "status":
      return (
        <div className="departure-time__status">{time.pages[currentPage]}</div>
      );

    case "overnight":
      return <MoonIcon width={128} height={128} color="black" />;
  }
};

interface Props {
  time?: DepartureTime;
  scheduled_time?: DepartureTime;
  is_live: boolean;
}

const DepartureTime: ComponentType<Props> = ({
  time,
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
        <DepartureTimePart currentPage={currentPage} time={time} />
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
        <DepartureTimePart {...{ time: scheduled_time, currentPage }} />
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
