import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const env = {
  ...process.env,
  PLAYWRIGHT_PORT: process.env.PLAYWRIGHT_PORT || '3201',
  PLAYWRIGHT_USE_START: 'true',
};

const child = spawn('npx playwright test e2e/acik-menu-canli.spec.ts', {
  cwd: appDir,
  env,
  stdio: 'inherit',
  shell: true,
});

child.on('close', (code) => {
  process.exit(code ?? 1);
});
