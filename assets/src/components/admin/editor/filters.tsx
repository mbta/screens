import { type ComponentType, useState } from "react";
import { AUTOLESS_ATTRIBUTES, type JSON } from "Util/admin";

/**
 * Specifies a component that allows setting a filter function to be applied to
 * screen configuration values.
 *
 * - `update` is a function that updates the filter function: `undefined` if no
 *   filter should be applied, or a function that accepts a screen config value
 *   and returns a boolean indicating whether to include it in the results
 */
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

export const JsonFilter: Filter = ({ update }) => {
  const [hasChanged, setHasChanged] = useState(false);

  // Stringify JSON the same way as `JsonInput` so this filter effectively
  // searches through the visible contents of each input. This makes it more
  // intuitive to search for partial key-value pairs (e.g. `"read_as": "` to
  // search for headers that have a non-null audio override), though also means
  // it's not possible to match on a structure that spans multiple lines in the
  // formatted JSON.
  const doUpdate = (inputValue) => {
    update(
      inputValue
        ? (value) => JSON.stringify(value, null, 2).includes(inputValue)
        : undefined,
    );
    setHasChanged(false);
  };

  return (
    <form
      onSubmit={(e) => {
        doUpdate((e.target as HTMLFormElement).elements["input"].value);
        e.preventDefault();
      }}
    >
      <input
        {...AUTOLESS_ATTRIBUTES}
        className="admin-editor__json-filter"
        name="input"
        onBlur={(e) => doUpdate(e.target.value)}
        onChange={() => setHasChanged(true)}
        placeholder="Search"
      />
      {hasChanged && <button type="submit">🔎</button>}
    </form>
  );
};

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
