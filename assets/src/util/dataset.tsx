// Functions to get values from the #app div's data attributes.

/**
 * Gets the entire dataset.
 */
export const getDataset = () => document.getElementById("app")?.dataset ?? {};

/**
 * Gets one value from the dataset, or undefined if the key is not present.
 */
export const getDatasetValue = (key: string) => getDataset()[key];

/**
 * Gets one value from the dataset, or throws an error if the key is not present.
 */
export const fetchDatasetValue = (key: string) => {
  const dataset = getDataset();
  if (key in dataset) {
    return dataset[key] as string;
  } else {
    throw new Error(`key "${key}" missing from #app div data attributes`);
  }
};
