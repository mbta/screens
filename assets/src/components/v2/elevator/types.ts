import { type Pill } from "Components/v2/departures/route_pill";

export type StationWithClosures = {
  id: string;
  name: string;
  route_icons: Pill[];
  closures: Closure[];
};

export type Closure = {
  id: string;
  elevator_name: string;
  elevator_id: string;
  description: string;
  header_text: string;
};
