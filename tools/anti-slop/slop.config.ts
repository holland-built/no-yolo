import { defineConfig } from "oxlint";

// Shared anti-slop config. One copy for every project: nothing is vendored into
// the projects themselves. Rules are warnings, because this is a read-only
// review pass, not a build gate.
//
// Off on purpose (the author's taste, and they fight this code):
//   require-readable-spacing  - blank lines between statements, 6,169 hits on Wayfinder
//   no-runtime-typeof         - typeof is how plain JS narrows
//   no-object-parameters      - React props are objects
const rules = [
  "no-unknown-parameters",
  "no-unknown-returns",
  "no-unknown-type-aliases",
  "no-unsafe-dictionary-type",
  "no-chained-type-assertions",
  "no-widen-then-assert",
  "no-known-value-widening",
  "require-safety-comment-for-type-assertion",
  "no-array-filter-map",
  "no-reduce-accumulator-copy",
  "no-conditional-empty-object-spread",
  "no-module-mocking",
  "no-reflect-apply",
  "no-reflect-get",
  "no-shape-in-symbol-names",
];

export default defineConfig({
  plugins: [],
  categories: { correctness: "off" },
  ignorePatterns: [
    "**/node_modules/**",
    "**/.next/**",
    "**/dist/**",
    "**/build/**",
    "**/coverage/**",
  ],
  jsPlugins: [{ name: "anti-slop", specifier: "./src/index.ts" }],
  rules: Object.fromEntries(rules.map((r) => ["anti-slop/" + r, "warn"])),
});
