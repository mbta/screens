// https://jestjs.io/docs/configuration

/* eslint-disable @typescript-eslint/no-require-imports */
/* global require, module */

const requireJSON5 = require("require-json5");
const { pathsToModuleNameMapper } = require("ts-jest");
const { compilerOptions } = requireJSON5("./tsconfig");

/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  errorOnDeprecated: true,
  resetMocks: true,
  modulePaths: [compilerOptions.baseUrl],
  moduleNameMapper: pathsToModuleNameMapper(compilerOptions.paths),
};
