import type { ComponentType } from "react";

import { useCurrentPage } from "Context/dup_page";
import MoonIcon from "Images/moon.svg";
import { classWithModifier, classWithModifiers } from "Util/utils";

type DepartureTime =
  | { type: "text"; text: string }
  | { type: "minutes"; minutes: number }
  | { type: "timestamp"; hour: number; minute: number; am_pm: string | null }
  | { type: "overnight" };

const DepartureTimePart: ComponentType<DepartureTime> = (time) => {
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

  if (currentPage === 0 || !scheduled_time) {
    return (
      <div className={classWithModifier("departure-time", time.type)}>
        <DepartureTimePart {...time} />
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
        <DepartureTimePart {...scheduled_time} />
      </div>
    );
  }
};

export default DepartureTime;
