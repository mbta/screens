import { type ComponentType, useLayoutEffect, useRef, useState } from "react";

import type DestinationBase from "Components/departures/destination";
import { useCurrentPage } from "Context/dup_page";
import { classWithModifier, hasOverflowX } from "Util/utils";

type DupDestination = DestinationBase & { classModifier: string };

export const PHASES = {
  OneLine: "ONE_LINE",
  TwoLines: "TWO_LINES",
  Done: "DONE",
} as const;

export type PHASES = (typeof PHASES)[keyof typeof PHASES];

type SizingState = {
  headsignIndex: number;
  headsigns: string[];
  partsIndex1: number;
  partsIndex2: number;
  partsLength: number;
  phase: PHASES;
  firstLineFits: boolean;
  secondLineFits: boolean;
};

// Types representing state changes as we try different headsign variations
type FinishedUpdate = {
  phase: typeof PHASES.Done;
  partsIndex1?: number;
  partsIndex2?: number;
};
type IndexUpdate = {
  headsignIndex?: number;
  partsIndex1?: number;
  partsIndex2?: number;
};
type PhaseUpdate = { phase: typeof PHASES.TwoLines; headsignIndex: number };

export type SizingStateUpdate = FinishedUpdate | PhaseUpdate | IndexUpdate;

// Returns the next state given current state and line-fit measurements,
// or null if no update is needed (phase is already DONE or refs are absent).
export const nextSizingState = (
  state: SizingState,
): SizingStateUpdate | null => {
  const {
    phase,
    headsignIndex,
    headsigns,
    partsIndex1,
    partsIndex2,
    partsLength,
    firstLineFits,
    secondLineFits,
  } = state;
  const canAdjustSecondLine = partsIndex2 - 1 > partsIndex1;

  switch (phase) {
    case PHASES.OneLine:
      if (firstLineFits) {
        return {
          partsIndex1: partsLength,
          partsIndex2: partsLength,
          phase: PHASES.Done,
        };
      } else if (headsignIndex < headsigns.length - 1) {
        // Try shortened version of the headsign if available
        return { headsignIndex: headsignIndex + 1 };
      } else {
        // No shorter version available; try to fit full headsign on 2 lines.
        return { headsignIndex: 0, phase: PHASES.TwoLines };
      }

    case PHASES.TwoLines:
      // Don't abbreviate if we fit on two lines either way
      if (firstLineFits && secondLineFits) {
        return { phase: PHASES.Done };
      } else {
        if (!firstLineFits && partsIndex1 > 1) {
          // Try all possible positions for the line break
          return { partsIndex1: partsIndex1 - 1 };
        } else if (headsignIndex < headsigns.length - 1) {
          // Try to fit a full abbreviated headsign on 2 pages
          const nextParts = headsigns[headsignIndex + 1].split(" ");
          return {
            partsIndex1: nextParts.length,
            partsIndex2: nextParts.length,
            headsignIndex: headsignIndex + 1,
          };
        } else if (!secondLineFits && canAdjustSecondLine) {
          // The shortest headsign doesn't fit on 2 lines
          // Adjust the second line break to fit full words onto 2nd page
          return { partsIndex2: partsIndex2 - 1 };
        } else {
          return { phase: PHASES.Done };
        }
      }
    default:
      return null;
  }
};

const RenderedDestination = ({ parts, index1, index2, classModifier }) => {
  const currentPage = useCurrentPage();

  let pageContent: string;

  if (index1 === parts.length) {
    pageContent = parts.join(" ");
  } else {
    const pages = [
      parts.slice(0, index1).join(" ") + "…",
      "…" + parts.slice(index1, index2).join(" "),
    ];
    pageContent = pages[currentPage];
  }

  return (
    <div className={classWithModifier("departure-destination", classModifier)}>
      <div className="departure-destination__headsign">{pageContent}</div>
    </div>
  );
};

const Destination: ComponentType<DupDestination> = ({
  headsigns,
  classModifier,
}) => {
  const firstLineRef = useRef<HTMLDivElement>(null);
  const secondLineRef = useRef<HTMLDivElement>(null);

  const [headsignIndex, setHeadsignIndex] = useState(0);
  const parts = headsigns[headsignIndex].split(" ");
  const [partsIndex1, setPartsIndex1] = useState(parts.length);
  const [partsIndex2, setPartsIndex2] = useState(parts.length);
  const [phase, setPhase] = useState<PHASES>(PHASES.OneLine);

  /* eslint-disable-next-line react-hooks/exhaustive-deps --
   * TODO: Replace this with `useAutoSize`. For now, we know this logic cannot
   * cause infinite update loops, so we don't need to be warned that it might.
   */
  useLayoutEffect(() => {
    // First attempt to fit headsign on a single line. Prefer fitting an abbreviated
    // headsign on a single line than the full headsign across 2 pages.
    // If that doesn't work, try to fit it on two lines by adjusting
    // between which words we paginate. Move through abbreviations until we find fit.
    if (
      firstLineRef.current &&
      secondLineRef.current &&
      phase !== PHASES.Done
    ) {
      const next = nextSizingState({
        phase,
        headsignIndex,
        partsIndex1,
        partsIndex2,
        partsLength: parts.length,
        headsigns: headsigns,
        firstLineFits: !hasOverflowX(firstLineRef.current),
        secondLineFits: !hasOverflowX(secondLineRef.current),
      });
      if (next) {
        // Update the state so we can re-attempt sizing with updated values
        if ("headsignIndex" in next && next.headsignIndex !== undefined) {
          setHeadsignIndex(next.headsignIndex);
        }
        if ("phase" in next && next.phase !== undefined) {
          setPhase(next.phase);
        }
        if ("partsIndex1" in next && next.partsIndex1 !== undefined) {
          setPartsIndex1(next.partsIndex1);
        }
        if ("partsIndex2" in next && next.partsIndex2 !== undefined) {
          setPartsIndex2(next.partsIndex2);
        }
      }
    }
  });

  // Render paged version when done determining breaks
  if (phase === PHASES.Done) {
    return (
      <RenderedDestination
        index1={partsIndex1}
        index2={partsIndex2}
        parts={parts}
        classModifier={classModifier}
      />
    );
  }

  // Version just for determining line breaks, never visible to riders
  let firstLine: string;
  let secondLine: string;
  if (phase === PHASES.OneLine) {
    firstLine = headsigns[headsignIndex];
    secondLine = "";
  } else {
    console.log(
      `parts: ${parts}, partsIndex1: ${partsIndex1}, partsIndex2: ${partsIndex2}`,
    );
    firstLine = parts.slice(0, partsIndex1).join(" ") + "…";
    secondLine = "…" + parts.slice(partsIndex1, partsIndex2).join(" ");
  }

  return (
    <div className={classWithModifier("departure-destination", classModifier)}>
      <div className="departure-destination__headsign" ref={firstLineRef}>
        {firstLine}
      </div>
      <div className="departure-destination__headsign" ref={secondLineRef}>
        {secondLine}
      </div>
    </div>
  );
};

export default Destination;
