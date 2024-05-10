import { describe, expect, test } from "@jest/globals";

import { Section } from "Components/v2/departures/section";
import { trimSections } from "Components/v2/departures/section";

import { departureRow, normalSection, timeWithCrowding } from "./factories";

describe("trimSections", () => {
  test("does nothing with notice sections", () => {
    const sections: Section[] = [
      {
        type: "notice_section",
        text: { text: [{ text: "text" }] },
      },
    ];

    expect(trimSections(sections)).toBe(sections);
  });

  test("trims all sections to their `max` if any exceed it", () => {
    const rowsA = departureRow.buildList(3);
    const [rowA1, rowA2] = rowsA;
    const rowsB = departureRow.buildList(5);
    const [rowB1, rowB2, rowB3] = rowsB;

    const sections = [
      normalSection.build({ layout: { max: 2 }, rows: rowsA }),
      normalSection.build({ layout: { max: 3 }, rows: rowsB }),
    ];

    expect(trimSections(sections)).toEqual([
      { ...sections[0], rows: [rowA1, rowA2] },
      { ...sections[1], rows: [rowB1, rowB2, rowB3] },
    ]);
  });

  test("trims one departure from the largest section above its `base`", () => {
    const rowsB = departureRow.buildList(5);
    const [rowB1, rowB2, rowB3, rowB4] = rowsB;

    const sections = [
      normalSection.build({
        layout: { base: 2 },
        rows: departureRow.buildList(3),
      }),
      normalSection.build({ layout: { base: 2 }, rows: rowsB }),
      normalSection.build({
        layout: { base: 2 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toEqual([
      { ...sections[0] },
      { ...sections[1], rows: [rowB1, rowB2, rowB3, rowB4] },
      { ...sections[2] },
    ]);
  });

  test("treats sections with a null `base` as being equal to `min`", () => {
    const rowsA = departureRow.buildList(3);
    const [rowA1, rowA2] = rowsA;

    const sections = [
      normalSection.build({ layout: { min: 1, base: null }, rows: rowsA }),
      normalSection.build({
        layout: { min: 1, base: 2 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toEqual([
      { ...sections[0], rows: [rowA1, rowA2] },
      { ...sections[1] },
    ]);
  });

  test("trims one departure from the largest section above its `min`", () => {
    const rowsA = departureRow.buildList(3);
    const [rowA1, rowA2] = rowsA;

    const sections = [
      normalSection.build({ layout: { min: 1 }, rows: rowsA }),
      normalSection.build({
        layout: { min: 3 },
        rows: departureRow.buildList(3),
      }),
      normalSection.build({
        layout: { min: 1 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toEqual([
      { ...sections[0], rows: [rowA1, rowA2] },
      { ...sections[1] },
      { ...sections[2] },
    ]);
  });

  test("returns the original array if no sections are over their `min`", () => {
    const sections = [
      normalSection.build({
        layout: { min: 2 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toBe(sections);
  });

  test("trims individual departure times from rows with multiple", () => {
    const times = timeWithCrowding.buildList(3);
    const [time1, time2] = times;
    const row = departureRow.build({ times_with_crowding: times });
    const trimmedRow = { ...row, times_with_crowding: [time1, time2] };

    const sections = [normalSection.build({ rows: [row] })];

    expect(trimSections(sections)).toEqual([
      { ...sections[0], rows: [trimmedRow] },
    ]);
  });
});
