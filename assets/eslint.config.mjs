import globals from "globals";
import pluginJs from "@eslint/js";
import tseslint from "typescript-eslint";
import pluginReact from "eslint-plugin-react";
import pluginReactHooks from "eslint-plugin-react-hooks";
import eslintConfigPrettier from "eslint-config-prettier";
import jestPlugin from "eslint-plugin-jest";

export default [
  { languageOptions: { globals: globals.browser } },
  pluginJs.configs.recommended,
  ...tseslint.configs.recommended,
  pluginReact.configs.flat.recommended,
  pluginReact.configs.flat["jsx-runtime"],
  eslintConfigPrettier,
  {
    files: ["test/**"],
    ...jestPlugin.configs["flat/style"],
  },
  {
    files: ["**/*.{ts,tsx}"],
    plugins: {
      "react-hooks": pluginReactHooks,
    },
    rules: {
      ...pluginReactHooks.configs.recommended.rules,
      "react-hooks/exhaustive-deps": "error",
    },
  },
  {
    settings: { react: { version: "detect" } },
    rules: {
      eqeqeq: "error",
      "no-empty": ["error", { allowEmptyCatch: true }],
      "react/display-name": "warn",
      // In addition to the deprecated React `propTypes`, this rule supposedly
      // can detect when types of props are specified in TypeScript, but that
      // doesn't seem to be working and it raises an error on every component.
      // See: https://github.com/jsx-eslint/eslint-plugin-react/issues/3753#issuecomment-2189377576
      "react/prop-types": "off",
      "@typescript-eslint/ban-ts-comment": "warn",
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unused-vars": [
        // https://typescript-eslint.io/rules/no-unused-vars/
        "error",
        {
          args: "all",
          argsIgnorePattern: "^_",
          caughtErrors: "all",
          caughtErrorsIgnorePattern: "^_",
          destructuredArrayIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],
    },
  },
];
