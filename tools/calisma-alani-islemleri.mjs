#!/usr/bin/env node

import path from "node:path";
import { rmSync } from "node:fs";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");

function abs(...parts) {
  return path.resolve(repoRoot, ...parts);
}

function removeIfExists(relativePath) {
  rmSync(abs(relativePath), { recursive: true, force: true });
}

function cleanWorkspace() {
  [
    "uygulamalar/web/.next",
    "uygulamalar/web/node_modules/.cache",
    "uygulamalar/mobil/build",
    "uygulamalar/mobil/.dart_tool",
  ].forEach(removeIfExists);
}

function printUsage() {
  console.log("Usage: node tools/calisma-alani-islemleri.mjs <clean>");
}

const command = process.argv[2];

switch (command) {
  case "clean":
    cleanWorkspace();
    break;
  default:
    printUsage();
    process.exit(1);
}
