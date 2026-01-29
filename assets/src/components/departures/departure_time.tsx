import type { ComponentType } from "react";

import { useCurrentPage } from "Context/dup_page";
import MoonIcon from "Images/moon.svg";
import { classWithModifier, classWithModifiers } from "Util/utils";

type DepartureTime =
  | { type: "text"; text: string }
  | { type: "minutes"; minutes: number }
  | { type: "timestamp"; hour: number; minute: number; am_pm: string | null }
  | { type: "stops_away"; prefix: string; suffix: string }
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

    case "stops_away":
      // Show prefix ("Stopped") on page 0, suffix ("N stop(s) away") on page 1
      const text = currentPage === 0 ? time.prefix : time.suffix;
      return <div className="departure-time__stops_away">{text}</div>;

    case "overnight":
      return <MoonIcon width={128} height={128} color="black" />;
  }
};

interface Props {
  time: DepartureTime;
  scheduled_time?: DepartureTime;
}

const DepartureTime: ComponentType<Props> = ({ time, scheduled_time }) => {
  const currentPage = useCurrentPage();

  if (!scheduled_time || (time.type !== "stops_away" && currentPage === 0)) {
    return (
      <div className={classWithModifier("departure-time", time.type)}>
        <DepartureTimePart {...{ time, currentPage }} />
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
        <DepartureTimePart {...{ time: scheduled_time, currentPage }} />
      </div>
    );
  }
};

export default DepartureTime;
