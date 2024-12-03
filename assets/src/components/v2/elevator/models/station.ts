import { type Pill } from "Components/v2/departures/route_pill";
import { type Closure } from "Components/v2/elevator/models/closure";

export type StationWithClosures = {
  id: string;
  name: string;
  route_icons: Pill[];
  closures: Closure[];
};
