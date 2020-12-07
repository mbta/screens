import moment from "moment";
import "moment-timezone";

moment.tz.setDefault("America/New_York");

export type TimeRepresentation =
  | { type: "TEXT"; text: string }
  | { type: "MINUTES"; minutes: number }
  | { type: "TIMESTAMP"; timestamp: string; ampm: string };

export const timeRepresentationsEqual = (rep1, rep2) => {
  if (!rep1 || !rep2) {
    return false;
  }
  if (rep1.type !== rep2.type) {
    return false;
  }

  if (rep1.type === "TIMESTAMP") {
    return rep1.ampm === rep2.ampm && rep1.timestamp === rep2.timestamp;
  }

  if (rep1.type === "MINUTES") {
    return rep1.minutes === rep2.minutes;
  }

  if (rep1.type === "TEXT") {
    return rep1.text === rep2.text;
  }
};

export const standardTimeRepresentation = (
  departureTimeString: string,
  currentTimeString: string,
  vehicleStatus: string,
  stopType: string,
  noMinutes: boolean,
  forceTimestamp: boolean
): TimeRepresentation => {
  const departureTime = moment(departureTimeString);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (!forceTimestamp) {
    if (vehicleStatus === "stopped_at" && secondDifference <= 90) {
      return { type: "TEXT", text: "BRD" };
    }

    if (secondDifference <= 30) {
      if (stopType === "first_stop") {
        return { type: "TEXT", text: "BRD" };
      }
      return { type: "TEXT", text: "ARR" };
    }

    if (minuteDifference < 60 && !noMinutes) {
      return { type: "MINUTES", minutes: minuteDifference };
    }
  }

  const timestamp = departureTime.format("h:mm");
  const ampm = departureTime.format("A");
  return {
    type: "TIMESTAMP",
    timestamp,
    ampm,
  };
};

export const einkTimeRepresentation = (
  departureTimeString: string,
  currentTimeString: string
): TimeRepresentation => {
  const departureTime = moment(departureTimeString);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (secondDifference < 60) {
    return { type: "TEXT", text: "Now" };
  } else if (minuteDifference < 60) {
    return { type: "MINUTES", minutes: minuteDifference };
  } else {
    const timestamp = departureTime.format("h:mm");
    const ampm = departureTime.format("A");
    return {
      type: "TIMESTAMP",
      timestamp,
      ampm,
    };
  }
};
