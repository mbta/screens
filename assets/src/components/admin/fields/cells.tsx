import { type ComponentType, useState } from "react";
import { Link } from "react-router";

import { type JSON, AUTOLESS_ATTRIBUTES } from "Util/admin";

export type Cell = ComponentType<{
  value: JSON;
  update: (value: JSON) => void;
}>;

const ifChanged = (
  input: HTMLInputElement | HTMLTextAreaElement,
  func: (value: string) => void,
) => {
  if (input.value !== input.defaultValue) func(input.value);
};

const tryParse = (text: string): JSON | undefined => {
  try {
    return JSON.parse(text);
  } catch (e) {
    if (e instanceof SyntaxError) {
      return undefined;
    } else {
      throw e;
    }
  }
};

export const buildSelectInput =
  (options: (string | null)[]): Cell =>
  ({ value, update }) => {
    const selectValue = (value as string | null) ?? undefined;

    return (
      <select onChange={(e) => update(e.target.value)} value={selectValue}>
        {options.map((opt) => (
          <option key={opt} value={opt ?? undefined}>
            {opt}
          </option>
        ))}
      </select>
    );
  };

export const CheckboxInput: Cell = ({ value, update }) => (
  <input
    type="checkbox"
    checked={value as boolean}
    onChange={(e) => update(e.target.checked)}
  />
);

export const InspectorLink: Cell = ({ value: id }) => (
  <Link
    to={`/inspector?id=${id}`}
    className="admin-table__inspector-link"
    title="🔍 View in Inspector"
  >
    {id as string}
  </Link>
);

export const JsonInput: Cell = ({ value, update }) => {
  const [isValid, setIsValid] = useState(true);

  const updateIfValid = (newValue) => {
    const json = tryParse(newValue);
    if (json !== undefined) update(json);
  };

  return (
    <div className="admin-table__input-container">
      <textarea
        {...AUTOLESS_ATTRIBUTES}
        className="admin-table__textarea"
        defaultValue={JSON.stringify(value, null, 2)}
        onChange={(e) => setIsValid(tryParse(e.target.value) !== undefined)}
        onBlur={(e) => ifChanged(e.target, updateIfValid)}
      />
      {!isValid && (
        <div>
          <small>❗️ Invalid JSON — will not be saved</small>
        </div>
      )}
    </div>
  );
};

export const StringInput: Cell = ({ value, update }) => (
  <input
    {...AUTOLESS_ATTRIBUTES}
    defaultValue={value as string}
    onBlur={(e) => ifChanged(e.target, (v) => update(v || null))}
  />
);
