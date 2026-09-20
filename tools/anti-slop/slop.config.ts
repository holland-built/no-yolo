import { defineConfig } from "oxlint";

// Shared anti-slop config. One copy for every project: nothing is vendored into
// the projects themselves. Rules are warnings, because this is a read-only
// review pass, not a build gate.
//
// Off on purpose (the author's taste, and they fight this code):
//   require-readable-spacing  - blank lines between statements, thousands of hits on a normal React codebase
//   no-runtime-typeof         - typeof is how plain JS narrows
//   no-object-parameters      - React props are objects
//
// Off on purpose (ceremony, not defects). These accounted for 1,612 of the 1,674
// hits on Wayfinder, and a second opinion from Codex judged every one of them
// noise against real, well-documented code:
//   require-safety-comment-for-type-assertion - 878 hits. A comment does not make
//     a cast safe, and the rule cannot see the typeof / Array.isArray guard that
//     already proved the cast two lines above it.
//   no-known-value-widening       - 204 hits, almost all legitimate.
//   no-unsafe-dictionary-type     - 188 hits. Record<string, unknown> is the right
//     type for genuinely dynamic key access.
//   no-shape-in-symbol-names      - 164 hits. "shape" is real domain language in
//     some codebases (a data tool shapes imported rows).
//   no-unknown-parameters         - 81 hits. `unknown` is the CORRECT type for
//     untrusted input; swapping in a named type is a downgrade, not a fix.
//   no-unknown-returns            - 12 hits. Correct for a parser's return.
//   no-array-filter-map           - 37 hits, style only.
//   no-module-mocking             - 26 hits, a test-design preference.
//   no-conditional-empty-object-spread - 24 hits, cosmetic.
//   no-unknown-type-aliases       - 0 hits, same family as the above.
const rules = [
  "no-chained-type-assertions",
  "no-widen-then-assert",
  "no-reduce-accumulator-copy",
  "no-reflect-apply",
  "no-reflect-get",
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
  overrides: [
    {
      // A test stub casts a partial object into a full one on purpose - that is
      // what a stub IS. The rule earns its keep in production code only.
      files: [
        "**/__tests__/**",
        "**/*.test.ts",
        "**/*.test.tsx",
        "**/*.spec.ts",
        "**/*.spec.tsx",
      ],
      rules: { "anti-slop/no-chained-type-assertions": "off" },
    },
  ],
});
