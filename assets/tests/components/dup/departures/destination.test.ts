import { describe, expect, test } from "@jest/globals";
import { nextSizingState, PHASES } from "Components/dup/departures/destination";

// Helper constants for different line fit scenarios
const fits = { firstLineFits: true, secondLineFits: true };
const firstOverflows = { firstLineFits: false, secondLineFits: true };
const secondOverflows = { firstLineFits: true, secondLineFits: false };
const bothOverflow = { firstLineFits: false, secondLineFits: false };

const oneLineBase = {
  phase: PHASES.ONE_LINE,
  headsignIndex: 0,
  partsIndex1: 3,
  partsIndex2: 3,
  partsLength: 3,
  headsignsLength: 1,
};

const twoLinesBase = {
  phase: PHASES.TWO_LINES,
  headsignIndex: 0,
  partsIndex1: 3,
  partsIndex2: 3,
  partsLength: 3,
  headsignsLength: 1,
};

describe("nextSizingState", () => {
  describe("PHASES.ONE_LINE", () => {
    test("transitions to DONE and resets indices when first line fits", () => {
      expect(nextSizingState({ ...oneLineBase, ...fits })).toEqual({
        partsIndex1: oneLineBase.partsLength,
        partsIndex2: oneLineBase.partsLength,
        phase: PHASES.DONE,
      });
    });

    test("advances to next headsign when overflow and a shorter version exists", () => {
      const state = { ...oneLineBase, headsignsLength: 2, ...bothOverflow };
      expect(nextSizingState(state)).toEqual({ headsignIndex: 1 });
    });

    test("transitions to TWO_LINES when overflow and no shorter headsign", () => {
      expect(nextSizingState({ ...oneLineBase, ...bothOverflow })).toEqual({
        headsignIndex: 0,
        phase: PHASES.TWO_LINES,
      });
    });
  });

  describe("PHASES.TWO_LINES", () => {
    test("transitions to DONE when both lines fit", () => {
      expect(nextSizingState({ ...twoLinesBase, ...fits })).toEqual({
        phase: PHASES.DONE,
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
        headsignsLength: 2,
        ...bothOverflow,
      };
      expect(nextSizingState(state)).toEqual({
        partsIndex1: state.partsLength,
        partsIndex2: state.partsLength,
        headsignIndex: 1,
      });
    });

    test("decrements partsIndex2 when second line overflows and canAdjustSecondLine is true", () => {
      // partsIndex2 - 1 > partsIndex1: 4 - 1 = 3 > 2
      const state = {
        ...twoLinesBase,
        partsIndex1: 2,
        partsIndex2: 4,
        ...secondOverflows,
      };
      expect(nextSizingState(state)).toEqual({ partsIndex2: 3 });
    });

    test("transitions to DONE when cannot adjust second line", () => {
      // partsIndex2 - 1 = 3 - 1 = 2 = partsIndex1, so canAdjustSecondLine is false
      const state = {
        ...twoLinesBase,
        partsIndex1: 2,
        partsIndex2: 3,
        ...secondOverflows,
      };
      expect(nextSizingState(state)).toEqual({ phase: PHASES.DONE });
    });

    test("transitions to DONE when no adjustments are possible", () => {
      // partsIndex1 === 1 (can't decrement), no shorter headsign, canAdjustSecondLine false
      const state = {
        ...twoLinesBase,
        partsIndex1: 1,
        partsIndex2: 2,
        ...bothOverflow,
      };
      expect(nextSizingState(state)).toEqual({ phase: PHASES.DONE });
    });
  });
});
