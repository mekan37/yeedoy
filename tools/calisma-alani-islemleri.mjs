#!/usr/bin/env node

import { cpSync, existsSync, mkdirSync, rmSync } from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const npmCmd = "npm";

function abs(...parts) {
  return path.resolve(repoRoot, ...parts);
}

function removeIfExists(relativePath) {
  rmSync(abs(relativePath), { recursive: true, force: true });
}

function ensureDir(relativePath) {
  mkdirSync(abs(relativePath), { recursive: true });
}

function copyDir(fromRelativePath, toRelativePath) {
  cpSync(abs(fromRelativePath), abs(toRelativePath), { recursive: true, force: true });
}

function copyFile(fromRelativePath, toRelativePath) {
  cpSync(abs(fromRelativePath), abs(toRelativePath), { force: true });
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? repoRoot,
    stdio: "inherit",
    shell: process.platform === "win32",
  });
  if (result.error) {
    console.error(`[workspace_ops] Komut calismadi: ${command} ${args.join(" ")}`);
    console.error(result.error.message);
    process.exit(1);
  }
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function cleanWorkspace() {
  [
    "uygulamalar/web/.next",
    "uygulamalar/web/node_modules/.cache",
    "uygulamalar/mobil/build",
    "uygulamalar/mobil/.dart_tool",
  ].forEach(removeIfExists);
}

function buildNext() {
  run(npmCmd, ["--prefix", "uygulamalar/web", "run", "build"]);
  removeIfExists("deploy/next");
  ensureDir("deploy/next");
  copyDir("uygulamalar/web/.next", "deploy/next/.next");
  if (existsSync(abs("uygulamalar/web/public"))) {
    copyDir("uygulamalar/web/public", "deploy/next/public");
  }
  copyFile("uygulamalar/web/package.json", "deploy/next/package.json");
  copyFile("uygulamalar/web/next.config.mjs", "deploy/next/next.config.mjs");
}

function printUsage() {
  console.log("Usage: node tools/calisma-alani-islemleri.mjs <clean|build-next|build-all>");
}

const command = process.argv[2];

switch (command) {
  case "clean":
    cleanWorkspace();
    break;
  case "build-next":
    buildNext();
    break;
  case "build-all":
    buildNext();
    break;
  default:
    printUsage();
    process.exit(1);
}
