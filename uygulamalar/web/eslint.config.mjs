import { defineConfig } from "eslint/config";
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";

export default defineConfig([
  {
    extends: [...nextCoreWebVitals],
  },
  {
    // eslint-config-next@16 bundles the newer eslint-plugin-react-hooks
    // (React Compiler readiness) rules — purity/set-state-in-effect/refs.
    // reactCompiler: true is now enabled (next.config.mjs). The only two
    // `refs` violations (stale-closure risk) were fixed, so that rule is
    // back to 'error'. `purity`/`set-state-in-effect` violations remain:
    // per Next.js/React docs, unaddressed violations cause a safe
    // per-component compiler bailout (no compilation, not a runtime bug),
    // and the remaining ones here are either inert Server Component
    // Date.now() reads or React-endorsed effect patterns (localStorage
    // sync, hydration guards, debounced fetch) — kept at 'warn' rather
    // than forcing a behavior-changing refactor.
    rules: {
      'react-hooks/purity': 'warn',
      'react-hooks/set-state-in-effect': 'warn',
      'react-hooks/refs': 'error',
    },
  },
]);