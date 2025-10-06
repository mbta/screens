import { type ComponentType, useState } from "react";
import { Link } from "react-router";

import { type JSON, AUTOLESS_ATTRIBUTES } from "Util/admin";

/**
 * Specifies a component that renders a screen configuration value and may allow
 * updating it.
 *
 * - `value` is the current value
 * - `update` is a function that updates the value
 * - `isNewScreen` is true if the screen this value is part of is "new"
 *   (exists only on the client side, has not been persisted yet)
 */
export type Cell = ComponentType<{
  value: JSON;
  update: (value: JSON) => void;
  isNewScreen?: boolean;
}>;

const ifChanged = (
  input: HTMLInputElement | HTMLTextAreaElement,
  func: (value: string) => void,
) => {
  if (input.value !== input.defaultValue) func(input.value);
};

type JSONParseResult =
  | { success: true; json: JSON }
  | { success: false; error: string };

const tryParse = (text: string): JSONParseResult => {
  try {
    return { success: true, json: JSON.parse(text) };
  } catch (e) {
    if (e instanceof SyntaxError) {
      return { success: false, error: e.message };
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

export const InspectorLink: Cell = ({ value: id, isNewScreen }) =>
  isNewScreen ? (
    <>✴️ {id as string}</>
  ) : (
    <Link
      to={`inspector?id=${id}`}
      className="admin-editor__inspector-link"
      title="🔍 View in Inspector"
    >
      {id as string}
    </Link>
  );

export const JsonInput: Cell = ({ value, update }) => {
  const [parseError, setParseError] = useState<string | null>(null);

  const updateIfValid = (newValue) => {
    const result = tryParse(newValue);
    if (result.success) update(result.json);
  };

  const updateParseError = (newValue) => {
    const result = tryParse(newValue);
    setParseError(result.success ? null : result.error);
  };

  return (
    <>
      <textarea
        {...AUTOLESS_ATTRIBUTES}
        className="admin-editor__textarea"
        defaultValue={JSON.stringify(value, null, 2)}
        onChange={(e) => updateParseError(e.target.value)}
        onBlur={(e) => ifChanged(e.target, updateIfValid)}
      />
      {parseError && (
        <div className="admin-editor__textarea__status">
          <small>❗️ {parseError}</small>
        </div>
      )}
    </>
  );
};

/**
 * String input whose value is `null` when empty.
 */
export const NullStringInput: Cell = ({ value, update }) => (
  <input
    {...AUTOLESS_ATTRIBUTES}
    defaultValue={value as string}
    onBlur={(e) => ifChanged(e.target, (v) => update(v || null))}
    placeholder="null"
  />
);

export const NumberInput: Cell = ({ value, update }) => (
  <input
    type="number"
    min={0}
    {...AUTOLESS_ATTRIBUTES}
    defaultValue={value as number}
    onBlur={(e) => ifChanged(e.target, (v) => update(parseInt(v)))}
  />
);

export const StringInput: Cell = ({ value, update }) => (
  <input
    {...AUTOLESS_ATTRIBUTES}
    defaultValue={value as string}
    onBlur={(e) => ifChanged(e.target, (v) => update(v))}
  />
);
