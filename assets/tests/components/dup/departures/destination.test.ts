import { describe, expect, test } from "@jest/globals";
import { nextSizingState, PHASES } from "Components/dup/departures/destination";

// Helper constants for different line fit scenarios
const fits = { firstLineFits: true, secondLineFits: true };
const firstOverflows = { firstLineFits: false, secondLineFits: true };
const secondOverflows = { firstLineFits: true, secondLineFits: false };
const bothOverflow = { firstLineFits: false, secondLineFits: false };

const oneLineBase = {
  phase: PHASES.OneLine,
  headsignIndex: 0,
  partsIndex1: 3,
  partsIndex2: 3,
  partsLength: 3,
  headsigns: ["Wonderland"],
};

const twoLinesBase = {
  phase: PHASES.TwoLines,
  headsignIndex: 0,
  partsIndex1: 3,
  partsIndex2: 3,
  partsLength: 3,
  headsigns: ["Wonderland"],
};

describe("nextSizingState", () => {
  describe("PHASES.OneLine", () => {
    test("transitions to DONE and resets indices when first line fits", () => {
      expect(nextSizingState({ ...oneLineBase, ...fits })).toEqual({
        partsIndex1: oneLineBase.partsLength,
        partsIndex2: oneLineBase.partsLength,
        phase: PHASES.Done,
      });
    });

    test("advances to next headsign when overflow and a shorter version exists", () => {
      const state = {
        ...oneLineBase,
        headsigns: ["Union Square", "Union Sq"],
        ...bothOverflow,
      };
      expect(nextSizingState(state)).toEqual({ headsignIndex: 1 });
    });

    test("transitions to TWO_LINES when overflow and no shorter headsign", () => {
      expect(nextSizingState({ ...oneLineBase, ...bothOverflow })).toEqual({
        headsignIndex: 0,
        phase: PHASES.TwoLines,
      });
    });
  });

  describe("PHASES.TwoLines", () => {
    test("transitions to DONE when both lines fit", () => {
      expect(nextSizingState({ ...twoLinesBase, ...fits })).toEqual({
        phase: PHASES.Done,
      });
    });

    test("decrements partsIndex1 when first line overflows and partsIndex1 > 1", () => {
      const state = { ...twoLinesBase, partsIndex1: 2, ...firstOverflows };
      expect(nextSizingState(state)).toEqual({ partsIndex1: 1 });
    });

    test("advances to next headsign when partsIndex1 is 1 and a shorter headsign exists", () => {
      const state = {
        ...twoLinesBase,
        partsIndex1: 1,
        headsigns: ["Union Square", "Union Sq"],
        ...bothOverflow,
      };
      expect(nextSizingState(state)).toEqual({
        partsIndex1: state.headsigns.length,
        partsIndex2: state.headsigns.length,
        headsignIndex: 1,
      });
    });

    test("decrements partsIndex2 when second line overflows and canAdjustSecondLine is true", () => {
      const state = {
        ...twoLinesBase,
        partsIndex1: 2,
        partsIndex2: 4,
        ...secondOverflows,
      };
      expect(nextSizingState(state)).toEqual({ partsIndex2: 3 });
    });

    test("transitions to DONE when cannot adjust second line", () => {
      const state = {
        ...twoLinesBase,
        partsIndex1: 2,
        partsIndex2: 3,
        ...secondOverflows,
      };
      expect(nextSizingState(state)).toEqual({ phase: PHASES.Done });
    });

    test("transitions to DONE when no adjustments are possible", () => {
      // partsIndex1 === 1 (can't decrement), no shorter headsign, canAdjustSecondLine false
      const state = {
        ...twoLinesBase,
        partsIndex1: 1,
        partsIndex2: 2,
        ...bothOverflow,
      };
      expect(nextSizingState(state)).toEqual({ phase: PHASES.Done });
    });
  });
});
