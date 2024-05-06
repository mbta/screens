/** @type {import('stylelint').Config} */

export default {
  extends: ["stylelint-config-standard-scss", "stylelint-config-recess-order"],
  reportDescriptionlessDisables: true,
  reportInvalidScopeDisables: true,
  reportNeedlessDisables: true,
  rules: {
    // We use blank lines to separate "groups" of imports.
    "at-rule-empty-line-before": null,

    // Docs: "We recommend turning this rule off if you use a lot of nesting."
    "no-descending-specificity": null,

    // Since we use SCSS exclusively, our `@import`s are all Sass imports
    // (which are allowed to appear anywhere in a file) and not native CSS
    // imports (which aren't, as this rule warns about).
    "no-invalid-position-at-import-rule": null,

    // Existing class/mixin names do not follow a single consistent scheme; for
    // now, these patterns just allow them all, while not allowing anything too
    // far beyond that. Most names are "BEM-like" (`block__element--modifier`).
    "selector-class-pattern": "^([A-Za-z][A-Za-z0-9]*)((--?|__?)[a-z0-9]+)*$",
    "scss/at-mixin-pattern": "^([A-Za-z][A-Za-z0-9]*)(--?[a-z0-9]+)*$",

    // We use blank lines to separate "groups" of variables.
    "scss/dollar-variable-empty-line-before": null,

    // Conflicts with Prettier, which breaks long lines involving operators by
    // putting operators at the ends of lines.
    "scss/operator-no-newline-after": null,
  },
};
