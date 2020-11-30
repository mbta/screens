import React, { useRef, useState, useEffect, useLayoutEffect } from "react";
import _ from "lodash";

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

// Adjustments to specific problematic headsigns
const REPLACEMENTS = {
  "Holbrook/Randolph": "Holbrook / Randolph",
  "Charlestown Navy Yard": "Charlestown",
  "Saugus Center via Kennedy Dr & Square One Mall":
    "Saugus Center via Kndy Dr & Square One",
  "Malden via Square One Mall & Kennedy Dr":
    "Malden via Square One Mall & Kndy Dr",
  "Washington St & Pleasant St Weymouth": "Washington St & Plsnt St Weymouth",
  "Woodland Rd via Gateway Center": "Woodland Rd via Gatew'y Center",
  "Sullivan (Limited Stops)": "Sullivan",
  "Ruggles (Limited Stops)": "Ruggles",
  "Wickford Junction": "Wickford Jct",
  "Needham Heights": "Needham Hts",
};

enum PHASES {
  ONE_LINE_FULL,
  ONE_LINE_ABBREV,
  TWO_LINES_FULL,
  TWO_LINES_ABBREV,
  DONE,
}

const RenderedDestination = ({ parts, index1, index2, page }) => {
  let currentPage;
  if (index1 === parts.length) {
    currentPage = parts.join(" ");
  } else {
    const pages = [
      parts.slice(0, index1).join(" ") + "…",
      "…" + parts.slice(index1, index2).join(" "),
    ];
    currentPage = pages[page];
  }

  return (
    <div className="base-departure-destination__container">
      <div className="base-departure-destination__primary">{currentPage}</div>
    </div>
  );
};

const Destination = ({ destination }) => {
  const [page, setPage] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setPage((p) => 1 - p);
    }, 3750);
    return () => clearInterval(interval);
  }, []);

  const firstLineRef = useRef(null);
  const secondLineRef = useRef(null);

  const correctedDestination = REPLACEMENTS[destination] || destination;
  let parts = correctedDestination.split(" ");

  const [index1, setIndex1] = useState(parts.length);
  const [index2, setIndex2] = useState(parts.length);
  const [abbreviate, setAbbreviate] = useState(false);
  const [phase, setPhase] = useState(PHASES.ONE_LINE_FULL);

  if (abbreviate) {
    parts = parts.map((p) => ABBREVIATIONS[p] || p);
  }

  useLayoutEffect(() => {
    if (firstLineRef.current && secondLineRef.current) {
      const firstLines = firstLineRef.current.clientHeight / LINE_HEIGHT;
      const secondLines = secondLineRef.current.clientHeight / LINE_HEIGHT;

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
        page={page}
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
    <div className="base-departure-destination__container">
      <div className="base-departure-destination__primary" ref={firstLineRef}>
        {firstLine}
      </div>
      <div className="base-departure-destination__primary" ref={secondLineRef}>
        {secondLine}
      </div>
    </div>
  );
};

export default Destination;
