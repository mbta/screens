// Elements of `middle_nodes` and `edges` describe the diagram's pieces in order, from left to right.
// `edges` will always have 1 more element than `middle_nodes`. For example:
// [l_end] -edge- [node] -edge- [node] -edge- [node] -edge- [r_end]
// 4 edges, 3 nodes
interface DisruptionDiagram {
  l_end: End;
  r_end: End;
  middle_nodes: Node[];
  edges: Edge[];
}

type End = Destination | TerminalNode;

interface Node {
  // Note the single ellipsis character, not 3 periods
  label: "…" | { full: string, abbrev: string };
  symbol: Symbol | null;
}

interface Destination {
  destination_id: TerminalStation | AggregateDestination;
}

interface TerminalNode {
  station_id: TerminalStation;
  symbol: Symbol;
}

// End labels appear to need hardcoded representations--they have line
// breaks and variably-styled text that we can't compute automatically.
//
// Note that treatment for the same destination can differ depending on whether it's on the left or right end, e.g. Medford/Tufts.
// I leave that logic to the client.
type TerminalStation =
  // Green Line
  | "place-lake"
  | "place-clmnl"
  | "place-river"
  | "place-hsmnl"
  | "place-gover"
  | "place-unsqu"
  | "place-mdftf"
  // Orange Line
  | "place-forhl"
  | "place-ogmnl"
  // Blue Line
  | "place-bomnl"
  | "place-wondl"
  // Red Line
  | "place-alfcl"
  | "place-asmnl"
  | "place-brntn";

type AggregateDestination =
  // Medford/Tufts & Union Square
  | "place-mdftf+place-unsqu"
  // North Station & Park Street
  | "place-north+place-pktrm"
  // Ashmont & Braintree
  | "place-asmnl+place-brntn";
// Any others?? These are just the ones I saw in the figma examples

type Edge = LineColor | DisruptionEdge;

type DisruptionEdge =
  | "dashed"
  | "thin";

type Symbol =
  // Color is always "black" -- might change pending design example for you-are-here shuttled station
  | { icon: "closed" | "shuttled", color: DisruptionColor }
  | { icon: "open", color: LineColor }
  // Color is always "you-are-here"
  | "you-are-here"
  | "you-are-here--outline";

type LineColor =
  | "blue"
  | "orange"
  | "red"
  | "green";

type DisruptionColor =
  | "black"
  // A slightly different red from "MBTA Red"
  | "you-are-here";

// We'll export additional types as needed
export { DisruptionDiagram };

/*
Client is responsible for:

- formatting label strings appropriately
  - Wrapping end labels onto a second line in certain cases (can this condition be determined automatically? Or do we need to hardcode the line-wrapping treatments?)
  - Abbreviating middle labels when necessary
  - Giving "to" and "&" a smaller type size, medium weight in destination labels
  - Using larger, bold font for left and right end labels
  - Using bold font for "you-are-here" station labels
- all positioning and sizing of:
  - destination arrows
  - stop symbols
    - the "closed" icon is smaller in suspensions than in station closures
  - line segments
  - shuttle bus dashes
  - labels
    - The horizontally-oriented '...' label occasionally used for a sequence of omitted stops gets offset to the right a bit
  - the diagram as a whole within its container
- icon variations
  - larger white margin around red "closed" icon for a bypassed you-are-here stop on the red line
  - larger icons for terminals

Q: Do we need to hardcode the typesetting for all end labels, or is there some procedure to determine them automatically?
     - It seems like we do need to hardcode at least some of them, so I made the data structure reflect that by assigning each one an ID
       which the client will use to look up how to render it.
Q: The rule for abbreviating middle-node labels** does not appear to be applied consistently in the figma examples. Is it correct?
   ** Abbreviate when label.height > 8 + max(l_end.label.height, r_end.label.height)
Q: What's the treatment for when the you-are-here stop is in the middle of a shuttle or suspension?
*/
