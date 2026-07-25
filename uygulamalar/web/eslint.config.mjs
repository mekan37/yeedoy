import { defineConfig } from "eslint/config";
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";

export default defineConfig([
  {
    extends: [...nextCoreWebVitals],
  },
  {
    // eslint-config-next@16 bundles the newer eslint-plugin-react-hooks
    // (React Compiler readiness) rules — purity/set-state-in-effect/refs.
    // We are NOT enabling reactCompiler in this Next 16 upgrade (separate,
    // deliberate PR later), so these are downgraded to warnings for now to
    // avoid a large unrelated refactor bundled into a version-bump PR.
    // Revisit when reactCompiler: true is actually turned on.
    rules: {
      'react-hooks/purity': 'warn',
      'react-hooks/set-state-in-effect': 'warn',
      'react-hooks/refs': 'warn',
    },
  },
]);