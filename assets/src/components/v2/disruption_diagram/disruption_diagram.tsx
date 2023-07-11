import React, { ComponentType } from "react";

type DisruptionDiagramData = ContinuousDisruptionDiagram | DiscreteDisruptionDiagram;

interface DisruptionDiagramBase {
  line: LineColor;
  current_station_slot_index: number;
  slots: [EndSlot, ...MiddleSlot[], EndSlot];
}

interface ContinuousDisruptionDiagram extends DisruptionDiagramBase {
  effect: "shuttle" | "suspension";
  // Range starts and ends at the effect region's *boundary stops*, inclusive.
  // For example in this scenario:
  //     0     1     2     3     4     5     6     7     8
  //    <= === O ========= O - - X - - X - - X - - O === O
  //                       |---------range---------|
  // The range is [3, 7].
  //
  // SPECIAL CASE:
  // If the range starts at 0 or ends at the last element of the array,
  // then the symbol for that terminal stop should use the appropriate
  // disruption symbol, not the "normal service" symbol.
  // For example if the range is [0, 5], the left end of the
  // diagram should use a disruption symbol:
  //     0     1     2     3     4     5     6     7     8
  //     X - - X - - X - - X - - X - - O ========= O === =>
  //     |------------range------------|
  effect_region_slot_index_range: [range_start: number, range_end: number];
}

interface DiscreteDisruptionDiagram extends DisruptionDiagramBase {
  effect: "station_closure";
  closed_station_slot_indices: number[];
}

interface EndSlot {
  type: "arrow" | "terminal";
  label_id: EndLabelID;
}

interface MiddleSlot {
  label: Label;
  show_symbol: boolean;
}

// Note the single ellipsis character, not 3 periods
type Label = "…" | { full: string, abbrev: string };

// End labels have hardcoded presentation, so we just send an ID for the client to use in
// a lookup.
//
// TBD what these IDs will look like. We might just use parent station IDs.
//
// The rest of the labels' presentations are computed based on the height of the end labels,
// so we can send actual text for those--it will be dynamically resized to fit.
type EndLabelID = string;

type LineColor =
  | "blue"
  | "orange"
  | "red"
  | "green";

/*
Client is responsible for:
- choosing the appropriate symbol for each slot based on whether the stop is inside/outside the effect region, whether it's the current stop, whether it's a Red Line diagram, whether show_symbol is true/false
- setting the appropriate label styles based on whether it's an end, whether it's the current stop, whether it's an ellipsis
- doing some sort of mapping/lookup like {endLabelID, leftOrRight} -> endLabelPresentation
- abbreviating middle labels when they're more than 8px taller than the tallest end label
- sizing, spacing, positioning of edges/end arrows/shuttle dashes/the diagram as a whole within its container
*/

const DisruptionDiagram: ComponentType<DisruptionDiagramData> = (_props) => {
  return (
    <div className="disruption-diagram">Diagram goes here!</div>
  );
};

export default DisruptionDiagram;
