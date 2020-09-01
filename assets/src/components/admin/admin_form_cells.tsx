import React, { forwardRef } from "react";

const FormStaticCell = forwardRef(({ value }, ref) => {
  return <input defaultValue={value} disabled={true} />;
});

const FormCell = forwardRef(({ value }, ref) => {
  return <input ref={ref} defaultValue={value} />;
});

const buildFormSelect = (options) => {
  const FormSelect = forwardRef(({ value }, ref) => {
    return (
      <select ref={ref} defaultValue={value}>
        <option value={undefined}></option>
        {options.map((opt) => (
          <option value={opt} key={opt}>
            {opt}
          </option>
        ))}
      </select>
    );
  });

  return FormSelect;
};

const FormBoolean = forwardRef(({ value }, ref) => {
  return (
    <select ref={ref} defaultValue={value}>
      <option value={undefined}></option>
      <option value={true}>True</option>
      <option value={false}>False</option>
    </select>
  );
});

const FormTextarea = forwardRef(({ value }, ref) => {
  const onBlur = (e) => {
    try {
      JSON.parse(e.target.value);
    } catch (err) {
      alert("Invalid JSON!");
    }
  };

  return (
    <textarea
      ref={ref}
      defaultValue={JSON.stringify(value, null, 2)}
      onBlur={onBlur}
    />
  );
});

export { FormCell, FormStaticCell, buildFormSelect, FormBoolean, FormTextarea };
