import React from "react";

const FormStaticCell = ({ value }) => {
  return <input defaultValue={value} disabled={true} />;
};

const FormTextCell = ({ value, header, setFormValues }) => {
  const onBlur = (e) => {
    const newValue = e.target.value || undefined;
    setFormValues((formValues) => ({
      ...formValues,
      [header]: newValue,
    }));
  };

  return <input defaultValue={value} onBlur={onBlur} />;
};

const buildFormSelect = (options, isNumber) => {
  const FormSelect = ({ value, header, setFormValues }) => {
    const onChange = (e) => {
      let newValue = e.target.value;
      if (isNumber) {
        newValue = parseInt(newValue, 10);
      }

      if (!(isNumber && isNaN(newValue))) {
        setFormValues((formValues) => ({
          ...formValues,
          [header]: newValue,
        }));
      }
    };

    return (
      <select onChange={onChange} defaultValue={value}>
        <option value={undefined}></option>
        {options.map((opt) => (
          <option value={opt} key={opt}>
            {opt}
          </option>
        ))}
      </select>
    );
  };

  return FormSelect;
};

const FormBoolean = ({ value, header, setFormValues }) => {
  const onChange = (e) => {
    let newValue;
    if (e.target.value === "true") {
      newValue = true;
    } else if (e.target.value === "false") {
      newValue = false;
    } else {
      newValue = undefined;
    }

    setFormValues((formValues) => ({
      ...formValues,
      [header]: newValue,
    }));
  };

  return (
    <select onChange={onChange} defaultValue={value}>
      <option value={undefined}></option>
      <option value={true}>True</option>
      <option value={false}>False</option>
    </select>
  );
};

const FormTextarea = ({ value, header, setFormValues }) => {
  const onBlur = (e) => {
    try {
      const json = JSON.parse(e.target.value);
      setFormValues((formValues) => ({ ...formValues, [header]: json }));
    } catch (err) {
      alert(err);
    }
  };

  return (
    <textarea onBlur={onBlur} defaultValue={JSON.stringify(value, null, 2)} />
  );
};

export {
  FormTextCell,
  FormStaticCell,
  buildFormSelect,
  FormBoolean,
  FormTextarea,
};
