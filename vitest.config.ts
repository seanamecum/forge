import { defineConfig } from "vitest/config";

// Scope tests to @forge/core so the nested atelier/ (Mira) project is never picked up.
export default defineConfig({
  test: {
    include: ["src/core/**/*.test.ts"],
  },
});
