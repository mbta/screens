import { describe, expect, test } from "@jest/globals";

import _ from "lodash/fp";

import {
  toFoldedSection,
  trimSections,
} from "Components/v2/departures/section";

import { departureRow, normalSection, timeWithCrowding } from "./factories";

const dropId = (rows) => rows.map((row) => _.omit(["id"], row));

describe("toFoldedSection", () => {
  test("trims departures above the section's `max`", () => {
    const rows = departureRow.buildList(5);
    const [row1, row2, row3, ...trimmed] = rows;

    const section = normalSection.build({ layout: { max: 3 }, rows: rows });

    expect(toFoldedSection(section)).toMatchObject({
      ...section,
      type: "folded_section",
      rows: { aboveFold: [row1, row2, row3], belowFold: dropId(trimmed) },
    });
  });
});

describe("trimSections", () => {
  const buildFoldedSection = (attrs) =>
    toFoldedSection(normalSection.build(attrs));

  test("trims one departure from the largest section above its `base`", () => {
    const rowsB = departureRow.buildList(5);
    const [rowB1, rowB2, rowB3, rowB4, ...trimmedB] = rowsB;

    const sections = [
      buildFoldedSection({
        layout: { base: 2 },
        rows: departureRow.buildList(3),
      }),
      buildFoldedSection({ layout: { base: 2 }, rows: rowsB }),
      buildFoldedSection({
        layout: { base: 2 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toMatchObject([
      { ...sections[0] },
      {
        ...sections[1],
        rows: {
          aboveFold: [rowB1, rowB2, rowB3, rowB4],
          belowFold: dropId(trimmedB),
        },
      },
      { ...sections[2] },
    ]);
  });

  test("treats sections with a null `base` as being equal to `min`", () => {
    const rowsA = departureRow.buildList(3);
    const [rowA1, rowA2, ...trimmedA] = rowsA;

    const sections = [
      buildFoldedSection({ layout: { min: 1, base: null }, rows: rowsA }),
      buildFoldedSection({
        layout: { min: 1, base: 2 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toMatchObject([
      {
        ...sections[0],
        rows: { aboveFold: [rowA1, rowA2], belowFold: dropId(trimmedA) },
      },
      sections[1],
    ]);
  });

  test("trims one departure from the largest section above its `min`", () => {
    const rowsA = departureRow.buildList(3);
    const [rowA1, rowA2, ...trimmedA] = rowsA;

    const sections = [
      buildFoldedSection({ layout: { min: 1 }, rows: rowsA }),
      buildFoldedSection({
        layout: { min: 3 },
        rows: departureRow.buildList(3),
      }),
      buildFoldedSection({
        layout: { min: 1 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toMatchObject([
      {
        ...sections[0],
        rows: { aboveFold: [rowA1, rowA2], belowFold: dropId(trimmedA) },
      },
      sections[1],
      sections[2],
    ]);
  });

  test("returns the original array if no sections are over their `min`", () => {
    const sections = [
      buildFoldedSection({
        layout: { min: 2 },
        rows: departureRow.buildList(2),
      }),
    ];

    expect(trimSections(sections)).toBe(sections);
  });

  test("trims individual departure times from rows with multiple", () => {
    const times = timeWithCrowding.buildList(3);
    const [time1, time2, ...trimmedTimes] = times;
    const row = departureRow.build({ times_with_crowding: times });
    const partialRow = { ...row, times_with_crowding: [time1, time2] };
    const trimmedRow = { ...row, times_with_crowding: trimmedTimes };

    const sections = [buildFoldedSection({ rows: [row] })];

    expect(trimSections(sections)).toMatchObject([
      { rows: { aboveFold: [partialRow], belowFold: dropId([trimmedRow]) } },
    ]);
  });
});
