import { type Pill } from "Components/v2/departures/route_pill";

export type StationWithClosures = {
  id: string;
  name: string;
  route_icons: Pill[];
  closures: Closure[];
  summary: string | null;
};

type Closure = {
  id: string;
  name: string;
};
