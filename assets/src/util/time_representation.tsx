import moment from "moment";
import "moment-timezone";

moment.tz.setDefault("America/New_York");

export type TimeRepresentation =
  | { type: "TEXT"; text: string }
  | { type: "MINUTES"; minutes: number }
  | { type: "TIMESTAMP"; timestamp: string; ampm: string };

export const standardTimeRepresentation = (
  departureTimeString: string,
  currentTimeString: string,
  vehicleStatus: string
): TimeRepresentation => {
  const departureTime = moment(departureTimeString);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (vehicleStatus === "stopped_at" && secondDifference <= 90) {
    return { type: "TEXT", text: "BRD" };
  }

  if (secondDifference <= 30) {
    return { type: "TEXT", text: "ARR" };
  }

  if (minuteDifference < 60) {
    return { type: "MINUTES", minutes: minuteDifference };
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
