import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Encore's `encore test` wires ENCORE_RUNTIME_LIB and runs this via `npm test`.
    globals: false,
    include: ["**/*.test.ts"],
    exclude: ["node_modules", "encore.gen"],
  },
});
