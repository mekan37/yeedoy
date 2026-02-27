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
const flutterCmd = "flutter";

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
    "apps/web_next/.next",
    "apps/web_next/node_modules/.cache",
    "apps/mobile_flutter/build",
    "apps/mobile_flutter/.dart_tool",
    "apps/panel_flutter_web/build",
    "apps/panel_flutter_web/.dart_tool",
  ].forEach(removeIfExists);
}

function buildOwner() {
  run(
    flutterCmd,
    ["build", "web", "--release", "--target", "lib/main_web_owner.dart", "--base-href", "/owner/"],
    { cwd: abs("apps/panel_flutter_web") },
  );
  removeIfExists("deploy/owner");
  ensureDir("deploy/owner");
  copyDir("apps/panel_flutter_web/build/web", "deploy/owner");
}

function buildAdmin() {
  run(
    flutterCmd,
    ["build", "web", "--release", "--target", "lib/main_web_admin.dart", "--base-href", "/admin/"],
    { cwd: abs("apps/panel_flutter_web") },
  );
  removeIfExists("deploy/admin");
  ensureDir("deploy/admin");
  copyDir("apps/panel_flutter_web/build/web", "deploy/admin");
}

function buildNext() {
  run(npmCmd, ["--prefix", "apps/web_next", "run", "build"]);
  removeIfExists("deploy/next");
  ensureDir("deploy/next");
  copyDir("apps/web_next/.next", "deploy/next/.next");
  if (existsSync(abs("apps/web_next/public"))) {
    copyDir("apps/web_next/public", "deploy/next/public");
  }
  copyFile("apps/web_next/package.json", "deploy/next/package.json");
  copyFile("apps/web_next/next.config.mjs", "deploy/next/next.config.mjs");
}

function printUsage() {
  console.log("Usage: node tools/workspace_ops.mjs <clean|build-owner|build-admin|build-next|build-all>");
}

const command = process.argv[2];

switch (command) {
  case "clean":
    cleanWorkspace();
    break;
  case "build-owner":
    buildOwner();
    break;
  case "build-admin":
    buildAdmin();
    break;
  case "build-next":
    buildNext();
    break;
  case "build-all":
    buildOwner();
    buildAdmin();
    buildNext();
    break;
  default:
    printUsage();
    process.exit(1);
}
