import moment from "moment";
import "moment-timezone";

moment.tz.setDefault("America/New_York");

export type TimeRepresentation =
  | { type: "text"; text: string }
  | { type: "minutes"; minutes: number }
  | { type: "timestamp"; timestamp: string; ampm: string };

export const timeRepresentationsEqual = (rep1, rep2) => {
  if (!rep1 || !rep2) {
    return false;
  } else if (rep1.type !== rep2.type) {
    return false;
  } else if (rep1.type === "timestamp") {
    return rep1.ampm === rep2.ampm && rep1.timestamp === rep2.timestamp;
  } else if (rep1.type === "minutes") {
    return rep1.minutes === rep2.minutes;
  } else if (rep1.type === "text") {
    return rep1.text === rep2.text;
  }

  return false; // impossible?
};

export const standardTimeRepresentation = (
  departureTimeString: string,
  currentTimeString: string,
  vehicleStatus: string,
  stopType: string,
  noMinutes?: boolean,
  forceTimestamp?: boolean,
): TimeRepresentation => {
  const departureTime = moment(departureTimeString);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (!forceTimestamp) {
    if (vehicleStatus === "stopped_at" && secondDifference <= 90) {
      return { type: "text", text: "BRD" };
    }

    if (secondDifference <= 30) {
      if (stopType === "first_stop") {
        return { type: "text", text: "BRD" };
      }
      return { type: "text", text: "ARR" };
    }

    if (minuteDifference < 60 && !noMinutes) {
      return { type: "minutes", minutes: minuteDifference };
    }
  }

  const timestamp = departureTime.format("h:mm");
  const ampm = departureTime.format("A");
  return {
    type: "timestamp",
    timestamp,
    ampm,
  };
};

export const einkTimeRepresentation = (
  departureTimeString: string,
  currentTimeString: string,
): TimeRepresentation => {
  const departureTime = moment(departureTimeString);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (secondDifference < 60) {
    return { type: "text", text: "Now" };
  } else if (minuteDifference < 60) {
    return { type: "minutes", minutes: minuteDifference };
  } else {
    const timestamp = departureTime.format("h:mm");
    const ampm = departureTime.format("A");
    return {
      type: "timestamp",
      timestamp,
      ampm,
    };
  }
};
