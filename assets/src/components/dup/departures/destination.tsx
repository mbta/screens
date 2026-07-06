import { type ComponentType, useLayoutEffect, useRef, useState } from "react";

import type DestinationBase from "Components/departures/destination";
import { useCurrentPage } from "Context/dup_page";
import { classWithModifier, hasOverflowX } from "Util/utils";

type DupDestination = DestinationBase & { classModifier: string };

// Global abbreviations
const ABBREVIATIONS = {
  Center: "Ctr",
  Square: "Sq",
  Court: "Crt",
  Circle: "Cir",
  South: "So",
  West: "W",
  Landing: "Ldg",
  One: "1",
  Washington: "Wash",
  Street: "St",
  College: "Col",
  Cleveland: "Clvlnd",
  Government: "Govt",
  "Medford/Tufts": "Medfd/Tufts",
};

enum PHASES {
  ONE_LINE,
  TWO_LINES,
  DONE,
}

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
  const [phase, setPhase] = useState(PHASES.ONE_LINE);
  
  const resetIndices = () => {
    setPartsIndex1(parts.length);
    setPartsIndex2(parts.length);
  };

  /* eslint-disable react-hooks/set-state-in-effect --
   * Similar to `useAutoSize`, setting state in an effect here is intentional
   * and a required part of the iterative approach to auto-sizing.
   */

  /* eslint-disable-next-line react-hooks/exhaustive-deps --
   * TODO: Replace this with `useAutoSize`. For now, we know this logic cannot
   * cause infinite update loops, so we don't need to be warned that it might.
   */
  useLayoutEffect(() => {
    // First attempt to fit headsign on a single line. Prefer fitting an abbreviated
    // headsign on a single line than the full headsign across 2 pages.
    // If that doesn't work, try to fit it on two lines by adjusting
    // between which words we paginate. Move through abbreviations until we find fit.
    if (firstLineRef.current && secondLineRef.current) {
      const firstLineFits = !hasOverflowX(firstLineRef.current);
      const secondLineFits = !hasOverflowX(secondLineRef.current);
      const canAdjustSecondLine = partsIndex2 > partsIndex1 + 1;

      switch (phase) {
        case PHASES.ONE_LINE:
          if (firstLineFits) {
            resetIndices();
            setPhase(PHASES.DONE);
          } else if (headsignIndex < headsigns.length - 1) {
          // Try shortened version of the headsign if available
            setHeadsignIndex(headsignIndex + 1);
          } else {
          // No shorter version available; try to fit full headsign on 2 lines.
            setHeadsignIndex(0);
            setPhase(PHASES.TWO_LINES);
          }
          break;

        case PHASES.TWO_LINES:
          // Don't abbreviate if we fit on two lines either way
          if (firstLineFits && secondLineFits) {
            setPhase(PHASES.DONE);
          } else {
            // Try all possible positions for the line break
            if (!firstLineFits && partsIndex1 > 1) {
              // Adjust position of 1st line break
              setPartsIndex1((n) => n - 1);
            } else if (headsignIndex < headsigns.length - 1) {
              // Try to fit abbreviated headsign on 2 pages
              resetIndices();
              setHeadsignIndex(headsignIndex + 1);
            } else if (!secondLineFits && canAdjustSecondLine) {
              // The shortest headsign doesn't fit on 2 lines
              // Adjust the second line break to fit full words onto 2nd page
              setPartsIndex2((n) => n - 1);
            }
            else {
              setPhase(PHASES.DONE);
            }
          }
          break;
      }
    }
  });

  /* eslint-enable react-hooks/set-state-in-effect */

  // Render paged version when done determining breaks
  if (phase === PHASES.DONE) {
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
  if (partsIndex1 === parts.length) {
    firstLine = parts.join(" ");
    secondLine = "";
  } else {
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
