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
  ONE_LINE_FULL,
  ONE_LINE_ABBREV,
  TWO_LINES_FULL,
  TWO_LINES_ABBREV,
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
  headsign,
  classModifier,
}) => {
  const firstLineRef = useRef<HTMLDivElement>(null);
  const secondLineRef = useRef<HTMLDivElement>(null);

  let parts = headsign.split(" ");

  const [index1, setIndex1] = useState(parts.length);
  const [index2, setIndex2] = useState(parts.length);
  const [abbreviate, setAbbreviate] = useState(false);
  const [phase, setPhase] = useState(PHASES.ONE_LINE_FULL);

  if (abbreviate) {
    parts = parts.map((p) => ABBREVIATIONS[p] || p);
  }

  /* eslint-disable-next-line react-hooks/exhaustive-deps --
   * TODO: Replace this with `useAutoSize`. For now, we know this logic cannot
   * cause infinite update loops, so we don't need to be warned that it might.
   */
  useLayoutEffect(() => {
    if (firstLineRef.current && secondLineRef.current) {
      const firstLineFits = !hasOverflowX(firstLineRef.current);
      const secondLineFits = !hasOverflowX(secondLineRef.current);

      switch (phase) {
        case PHASES.ONE_LINE_FULL:
          // Don't abbreviate if it already fits on one line.
          if (firstLineFits) {
            setPhase(PHASES.DONE);
          } else {
            setAbbreviate(true);
            setPhase(PHASES.ONE_LINE_ABBREV);
          }
          break;

        case PHASES.ONE_LINE_ABBREV:
          // Do abbreviate if it's the difference between fitting on one line and not.
          if (firstLineFits) {
            setPhase(PHASES.DONE);
          } else {
            setAbbreviate(false);
            setPhase(PHASES.TWO_LINES_FULL);
          }
          break;

        case PHASES.TWO_LINES_FULL:
          // Don't abbreviate if we fit on two lines either way
          if (firstLineFits && secondLineFits) {
            setPhase(PHASES.DONE);
          } else {
            // Try all possible positions for the line break
            if (index1 > 1) {
              setIndex1((n) => n - 1);
            } else {
              setIndex1(parts.length);
              setIndex2(parts.length);
              setAbbreviate(true);
              setPhase(PHASES.TWO_LINES_ABBREV);
            }
          }
          break;

        case PHASES.TWO_LINES_ABBREV:
          // Do abbreviate if it's the difference between fitting on two lines and not.
          // Cut off at 2 lines no matter what, so unexpected input doesn't wrap.
          if (!firstLineFits && index1 > 1) {
            // Find position of first line break
            setIndex1((n) => n - 1);
          } else if (!secondLineFits && index2 > index1 + 1) {
            // Find position of second line break
            setIndex2((n) => n - 1);
          } else {
            setPhase(PHASES.DONE);
          }
          break;
      }
    }
  });

  // Render paged version when done determining breaks
  if (phase === PHASES.DONE) {
    return (
      <RenderedDestination
        index1={index1}
        index2={index2}
        parts={parts}
        classModifier={classModifier}
      />
    );
  }

  // Version just for determining line breaks, never visible to riders
  let firstLine: string;
  let secondLine: string;
  if (index1 === parts.length) {
    firstLine = parts.join(" ");
    secondLine = "";
  } else {
    firstLine = parts.slice(0, index1).join(" ") + "…";
    secondLine = "…" + parts.slice(index1, index2).join(" ");
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
