import { describe, expect, test } from "@jest/globals";
import { adjustMinute } from "Util/timing";

describe("adjustMinute", () => {
  test("returns the difference between two datetimes, in minutes", () => {
    const departureTimeSeconds = new Date(
      new Date(2026, 7, 27, 13, 30, 45, 0).getTime() / 1000,
    );
    const currentDateTime = new Date(2026, 7, 27, 13, 25, 45, 0);

    const actual = adjustMinute(departureTimeSeconds, currentDateTime);

    expect(actual).toBe(5);
  });

  test("returns 1 when the two datetimes are the same", () => {
    const departureTimeSeconds = new Date(
      new Date(2026, 7, 27, 13, 30, 45, 0).getTime() / 1000,
    );
    const currentDateTime = new Date(2026, 7, 27, 13, 30, 45, 0);

    const actual = adjustMinute(departureTimeSeconds, currentDateTime);

    expect(actual).toBe(1);
  });

  test("returns 1 when the the current datetime is after the departure time are the same", () => {
    const departureTimeSeconds = new Date(
      new Date(2026, 7, 27, 13, 30, 45, 0).getTime() / 1000,
    );
    const currentDateTime = new Date(2026, 7, 27, 13, 35, 45, 0);

    const actual = adjustMinute(departureTimeSeconds, currentDateTime);

    expect(actual).toBe(1);
  });
});
