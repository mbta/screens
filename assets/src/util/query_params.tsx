// On Bus Screens update the state of their data based on values passed in through query params
// This list allows us to filter and only pass through valid params
export const URL_PARAMS_BY_SCREEN_TYPE = {
  on_bus_v2: ["route_id", "stop_id", "trip_id"],
};
