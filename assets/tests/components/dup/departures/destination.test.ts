import { describe, expect, test } from "@jest/globals";
import {
  buildPageContent,
  nextSizingState,
  PHASES,
} from "Components/dup/departures/destination";

describe("nextSizingState", () => {
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

describe("buildPageContent", () => {
  describe("message fits on the first line", () => {
    test("places all content in a single page", () => {
      const messageContent = ["Framingham"];

      const actual = buildPageContent({
        entireMessageByWord: messageContent,
        firstLineEndIndex: messageContent.length,
        secondLineEndIndex: messageContent.length, // fit the entire message
      });

      expect(actual).toEqual(messageContent);
    });
  });

  describe("message fits on both lines", () => {
    test("paginates the content", () => {
      const messageContent = "Readville v/ Fairmount".split(" ");

      const actual = buildPageContent({
        entireMessageByWord: messageContent,
        firstLineEndIndex: messageContent.length - 1, // "Readville v/"
        secondLineEndIndex: messageContent.length, // "Fairmount"
      });

      expect(actual).toEqual(["Readville v/…", "…Fairmount"]);
    });
  });

  describe("message doesn't fit on both lines", () => {
    test("paginates and truncates the content", () => {
      const messageContent =
        "Wickford Junction (Express to Sharon after Ruggles)".split(" ");

      const actual = buildPageContent({
        entireMessageByWord: messageContent,
        firstLineEndIndex: 3, // "Wickford Junction (Express"
        secondLineEndIndex: 5, // "to Sharon"
      });

      expect(actual).toEqual(["Wickford Junction (Express…", "…to Sharon…"]);
    });

    test("does not remove trailing 'via' shorthand on the second page", () => {
      const messageContent = "Forge Park/495 v/ Back Bay".split(" ");

      const actual = buildPageContent({
        entireMessageByWord: messageContent,
        firstLineEndIndex: 1, // "Forge"
        secondLineEndIndex: 3, // "Park/495 v/"
      });

      expect(actual).toEqual(["Forge…", "…Park/495 v/…"]);
    });

    test("pulls in the next word when the second page is only 'via' shorthand", () => {
      const messageContent = "Readville v/ Fairmount".split(" ");

      const actual = buildPageContent({
        entireMessageByWord: messageContent,
        firstLineEndIndex: 1, // "Readville"
        secondLineEndIndex: 2, // "v/"
      });

      expect(actual).toEqual(["Readville…", "…v/ Fairmount"]);
    });
  });
});
