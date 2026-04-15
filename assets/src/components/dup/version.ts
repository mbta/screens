/**
 * The value here is expected to be of the format:
 * `current_year.current_month.current_day.version_for_current_day`.
 *
 * Technically, this value can be _anything_. However, it does propagate to logs
 * to help determine which version of the client a given DUP data request is
 * coming from.
 */
export const DUP_VERSION = "26.04.15.1";
