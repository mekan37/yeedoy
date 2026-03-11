import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const nextDir = path.join(appDir, '.next');
const reportsDir = path.join(appDir, 'reports', 'build');
const logPath = path.join(reportsDir, 'build-latest.log');
const shouldAnalyze = process.argv.includes('--analyze');

fs.mkdirSync(reportsDir, { recursive: true });

await runCleanBuild({ analyze: shouldAnalyze });

async function runCleanBuild(options) {
  cleanNextArtifacts();

  const firstAttempt = await runBuild(options);
  if (firstAttempt.code === 0) return;

  if (shouldRetryAfterClean(firstAttempt.output)) {
    console.warn('[build] stale build artifact detected, retrying after second clean');
    cleanNextArtifacts();
    const secondAttempt = await runBuild(options);
    if (secondAttempt.code === 0) return;
    process.exit(secondAttempt.code ?? 1);
  }

  process.exit(firstAttempt.code ?? 1);
}

function cleanNextArtifacts() {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    try {
      fs.rmSync(nextDir, {
        recursive: true,
        force: true,
        maxRetries: 5,
        retryDelay: 200,
      });
      return;
    } catch (error) {
      if (attempt === 4) throw error;
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 250);
    }
  }
}

function runBuild({ analyze }) {
  return new Promise((resolve) => {
    const child = spawn('npm run build:next', {
      cwd: appDir,
      env: {
        ...process.env,
        ANALYZE: analyze ? 'true' : 'false',
      },
      shell: true,
      stdio: ['inherit', 'pipe', 'pipe'],
    });

    let output = '';

    child.stdout.on('data', (chunk) => {
      const value = chunk.toString();
      output += value;
      process.stdout.write(value);
    });

    child.stderr.on('data', (chunk) => {
      const value = chunk.toString();
      output += value;
      process.stderr.write(value);
    });

    child.on('close', (code) => {
      fs.writeFileSync(logPath, output, 'utf8');
      resolve({ code, output });
    });
  });
}

function shouldRetryAfterClean(output) {
  return (
    output.includes('/_document') ||
    output.includes('PageNotFoundError') ||
    (output.includes('ENOENT: no such file or directory') &&
      (output.includes('.next\\export\\404.html') ||
        output.includes('.next\\export\\500.html') ||
        output.includes('.next\\server\\pages-manifest.json') ||
        output.includes('.next/export/404.html') ||
        output.includes('.next/export/500.html') ||
        output.includes('.next/server/pages-manifest.json')))
  );
}
