import React, { useLayoutEffect, useRef, useState } from "react";

const LINE_HEIGHT = 138; // px

// Global abbreviations
const ABBREVIATIONS = {
  Center: "Ctr",
  Square: "Sq",
  Court: "Crt",
  Circle: "Circ",
  South: "So",
  West: "W",
  Landing: "Ldg",
  One: "1",
  Washington: "Wash",
};

enum PHASES {
  ONE_LINE_FULL,
  ONE_LINE_ABBREV,
  TWO_LINES_FULL,
  TWO_LINES_ABBREV,
  DONE,
}

const RenderedDestination = ({ parts, index1, index2, currentPageIndex }) => {
  let currentPage;
  if (index1 === parts.length) {
    currentPage = parts.join(" ");
  } else {
    const pages = [
      parts.slice(0, index1).join(" ") + "…",
      "…" + parts.slice(index1, index2).join(" "),
    ];
    currentPage = pages[currentPageIndex];
  }

  return (
    <div className="departure-destination">
      <div className="departure-destination__headsign">{currentPage}</div>
    </div>
  );
};

const Destination = ({ headsign, currentPage }) => {
  const firstLineRef = useRef(null);
  const secondLineRef = useRef(null);

  let parts = headsign.split(" ");

  const [index1, setIndex1] = useState(parts.length);
  const [index2, setIndex2] = useState(parts.length);
  const [abbreviate, setAbbreviate] = useState(false);
  const [phase, setPhase] = useState(PHASES.ONE_LINE_FULL);

  if (abbreviate) {
    parts = parts.map((p) => ABBREVIATIONS[p] || p);
  }

  useLayoutEffect(() => {
    if (firstLineRef.current && secondLineRef.current) {
      const firstLines = Math.round(
        firstLineRef.current.clientHeight / LINE_HEIGHT
      );
      const secondLines = Math.round(
        secondLineRef.current.clientHeight / LINE_HEIGHT
      );

      switch (phase) {
        case PHASES.ONE_LINE_FULL:
          // Don't abbreviate if it already fits on one line.
          if (firstLines === 1 && secondLines === 0) {
            setPhase(PHASES.DONE);
          } else {
            setAbbreviate(true);
            setPhase(PHASES.ONE_LINE_ABBREV);
          }
          break;

        case PHASES.ONE_LINE_ABBREV:
          // Do abbreviate if it's the difference between fitting on one line and not.
          if (firstLines === 1 && secondLines === 0) {
            setPhase(PHASES.DONE);
          } else {
            setAbbreviate(false);
            setPhase(PHASES.TWO_LINES_FULL);
          }
          break;

        case PHASES.TWO_LINES_FULL:
          // Don't abbreviate if we fit on two lines either way
          if (firstLines === 1 && secondLines === 1) {
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
          if (firstLines > 1 && index1 > 1) {
            // Find position of first line break
            setIndex1((n) => n - 1);
          } else if (secondLines > 1 && index2 > index1 + 1) {
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
        currentPageIndex={currentPage}
      />
    );
  }

  // Version just for determining line breaks, never visible to riders
  let firstLine;
  let secondLine;
  if (index1 === parts.length) {
    firstLine = parts.join(" ");
    secondLine = "";
  } else {
    firstLine = parts.slice(0, index1).join(" ") + "…";
    secondLine = "…" + parts.slice(index1, index2).join(" ");
  }

  return (
    <div className="departure-destination">
      <div className="departure-destination__headsign" ref={firstLineRef}>
        {firstLine}
      </div>
      <div className="departure-destination__variation" ref={secondLineRef}>
        {secondLine}
      </div>
    </div>
  );
};

export default Destination;
