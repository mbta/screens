import { Factory } from "fishery";

import { Section } from "Components/v2/departures/section";
import { Row } from "Components/v2/departures/normal_section";
import { TimeWithCrowding } from "Components/v2/departures/departure_times";

export const normalSection = Factory.define<Section>(() => ({
  type: "normal_section",
  layout: { min: 1, base: null, max: null, include_later: false },
  rows: departureRow.buildList(1),
  header: { title: null, arrow: null },
}));

export const departureRow = Factory.define<Row>(({ sequence }) => ({
  type: "departure_row",
  id: sequence.toString(),
  route: { type: "text", color: "yellow", text: sequence.toString() },
  headsign: { headsign: `Destination ${sequence}` },
  times_with_crowding: timeWithCrowding.buildList(1),
  inline_alerts: [],
}));

export const timeWithCrowding = Factory.define<TimeWithCrowding>(
  ({ sequence }) => ({
    id: sequence.toString(),
    time: { type: "minutes", minutes: sequence },
    crowding: null,
  }),
);
