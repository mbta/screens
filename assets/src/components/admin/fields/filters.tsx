import { type ComponentType } from "react";
import { type JSON } from "Util/admin";

export type Filter = ComponentType<{
  update: (filter: ((value: JSON) => boolean) | undefined) => void;
}>;

const BOOLEAN_FILTERS = {
  none: undefined,
  true: (value: JSON) => !!value,
  false: (value: JSON) => !value,
};

export const BooleanFilter: Filter = ({ update }) => (
  <select onChange={(e) => update(BOOLEAN_FILTERS[e.target.value])}>
    <option value="none"></option>
    <option value="true">true</option>
    <option value="false">false</option>
  </select>
);

export const buildSelectFilter =
  (options: string[]): Filter =>
  ({ update }) => (
    <select
      onChange={(e) =>
        update(e.target.value ? (value) => value === e.target.value : undefined)
      }
    >
      <option></option>
      {options.map((opt) => (
        <option key={opt} value={opt}>
          {opt}
        </option>
      ))}
    </select>
  );

export const StringFilter: Filter = ({ update }) => (
  <input
    onChange={(e) =>
      update(
        e.target.value
          ? (value) =>
              typeof value === "string" &&
              value.toLowerCase().includes(e.target.value.toLowerCase())
          : undefined,
      )
    }
    placeholder="Search"
  />
);
