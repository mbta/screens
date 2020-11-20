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

const PHASES = {
  ONE_LINE_FULL: 0,
  ONE_LINE_ABBREV: 1,
  TWO_LINES_FULL: 2,
  TWO_LINES_ABBREV: 3,
  DONE: 4,
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

  destination = REPLACEMENTS[destination] || destination;
  let parts = destination.split(" ");

  const [breakState, setBreakState] = useState({
    index1: parts.length,
    index2: parts.length,
    abbreviate: false,
    phase: PHASES.ONE_LINE_FULL,
  });

  if (breakState.abbreviate) {
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

      switch (breakState.phase) {
        case PHASES.ONE_LINE_FULL:
          // Don't abbreviate if it already fits on one line.
          if (firstLines === 1 && secondLines === 0) {
            setBreakState((s) => ({ ...s, phase: PHASES.DONE }));
          } else {
            setBreakState((s) => ({
              ...s,
              abbreviate: true,
              phase: PHASES.ONE_LINE_ABBREV,
            }));
          }
          break;

        case PHASES.ONE_LINE_ABBREV:
          // Do abbreviate if it's the difference between fitting on one line and not.
          if (firstLines === 1 && secondLines === 0) {
            setBreakState((s) => ({ ...s, phase: PHASES.DONE }));
          } else {
            setBreakState((s) => ({
              ...s,
              abbreviate: false,
              phase: PHASES.TWO_LINES_FULL,
            }));
          }
          break;

        case PHASES.TWO_LINES_FULL:
          // Don't abbreviate if we fit on two lines either way
          if (firstLines === 1 && secondLines === 1) {
            setBreakState((s) => ({ ...s, phase: PHASES.DONE }));
          } else {
            // Try all possible positions for the line break
            if (breakState.index1 > 1) {
              setBreakState(({ index1, ...s }) => ({
                ...s,
                index1: index1 - 1,
              }));
            } else {
              setBreakState({
                index1: parts.length,
                index2: parts.length,
                abbreviate: true,
                phase: PHASES.TWO_LINES_ABBREV,
              });
            }
          }
          break;

        case PHASES.TWO_LINES_ABBREV:
          // Do abbreviate if it's the difference between fitting on two lines and not.
          // Cut off at 2 lines no matter what, so unexpected input doesn't wrap.
          if (firstLines > 1 && breakState.index1 > 1) {
            // Find position of first line break
            setBreakState(({ index1, ...s }) => ({ ...s, index1: index1 - 1 }));
          } else if (
            secondLines > 1 &&
            breakState.index2 > breakState.index1 + 1
          ) {
            // Find position of second line break
            setBreakState(({ index2, ...s }) => ({ ...s, index2: index2 - 1 }));
          } else {
            setBreakState((s) => ({ ...s, phase: PHASES.DONE }));
          }
          break;
      }
    }
  });

  // Render paged version when done determining breaks
  if (breakState.phase === PHASES.DONE) {
    let currentPage;
    if (breakState.index1 === parts.length) {
      currentPage = parts.join(" ");
    } else {
      const pages = [
        parts.slice(0, breakState.index1).join(" ") + "...",
        "..." + parts.slice(breakState.index1, breakState.index2).join(" "),
      ];
      currentPage = pages[page];
    }

    return (
      <div className="base-departure-destination__container">
        <div className="base-departure-destination__primary">{currentPage}</div>
      </div>
    );
  }

  // Version just for determining line breaks, never visible to riders
  let firstLine;
  let secondLine;
  if (breakState.index1 === parts.length) {
    firstLine = parts.join(" ");
    secondLine = "";
  } else {
    firstLine = parts.slice(0, breakState.index1).join(" ") + "...";
    secondLine =
      "..." + parts.slice(breakState.index1, breakState.index2).join(" ");
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
