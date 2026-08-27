/**
 * Given two dates, compute the difference in minutes between `departureTimeSeconds`
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
export const adjustMinute = (
  departureTimeSeconds: Date,
  currentDateTime: Date,
): number => {
  const timeDifferenceSeconds =
    departureTimeSeconds.getTime() - currentDateTime.getTime() / 1000;
  const timeDifferenceMin = Math.floor(timeDifferenceSeconds / 60);
  return Math.max(timeDifferenceMin, 1);
};
