#!/usr/bin/env node

/**
 * Update references to the local tags module between semantic-release versions.
 *
 * Why this exists:
 * - Keeping release-time string replacements in a standalone script is easier
 *   to read, test, and maintain than an inline shell one-liner in .releaserc.
 * - It avoids platform-specific sed/find behavior differences.
 *
 * Expected arguments:
 *   1) last release version (for example: 1.2.3)
 *   2) next release version (for example: 1.2.4)
 *
 * Called by semantic-release exec plugin as:
 *   node scripts/release/update-tags-module-version.cjs "${lastRelease.version}" "${nextRelease.version}"
 */

const fs = require("fs");
const path = require("path");

const MODULES_ROOT = path.join("infrastructure", "modules");
const TARGET_FILE_NAMES = new Set(["context.tf", "readme.md"]);

const [lastVersion, nextVersion] = process.argv.slice(2);

if (!lastVersion || !nextVersion) {
  console.error(
    "Usage: node scripts/release/update-tags-module-version.cjs <lastVersion> <nextVersion>"
  );
  process.exit(1);
}

/**
 * Recursively list all files under a root directory.
 */
function listFilesRecursively(dirPath) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);

    if (entry.isDirectory()) {
      files.push(...listFilesRecursively(fullPath));
      continue;
    }

    files.push(fullPath);
  }

  return files;
}

/**
 * Ensure a semantic version has a leading v (for example 1.2.3 -> v1.2.3).
 */
function withVPrefix(version) {
  return version.startsWith("v") ? version : `v${version}`;
}

/**
 * Build equivalent from/to version pairs so replacements work for both:
 * - plain versions (1.2.3)
 * - v-prefixed tags (v1.2.3)
 */
function buildVersionPairs(fromVersion, toVersion) {
  const pairs = [
    { from: fromVersion, to: toVersion },
    { from: withVPrefix(fromVersion), to: withVPrefix(toVersion) }
  ];

  // De-duplicate if the input was already v-prefixed.
  return pairs.filter(
    (pair, index, all) =>
      all.findIndex((item) => item.from === pair.from && item.to === pair.to) === index
  );
}

/**
 * Replace all occurrences of release-pinned tags module references.
 */
function updateContent(content, fromVersion, toVersion) {
  let updated = content;

  for (const pair of buildVersionPairs(fromVersion, toVersion)) {
    updated = updated
      .replaceAll(
        `//infrastructure/modules/tags?ref=${pair.from}`,
        `//infrastructure/modules/tags?ref=${pair.to}`
      )
      .replaceAll(
        `//infrastructure/modules/tags | ${pair.from} |`,
        `//infrastructure/modules/tags | ${pair.to} |`
      );
  }

  return updated;
}

if (!fs.existsSync(MODULES_ROOT)) {
  console.error(`Directory not found: ${MODULES_ROOT}`);
  process.exit(1);
}

const allFiles = listFilesRecursively(MODULES_ROOT);
let updatedFilesCount = 0;

for (const filePath of allFiles) {
  const fileName = path.basename(filePath).toLowerCase();

  // Only process files where these references are expected.
  if (!TARGET_FILE_NAMES.has(fileName)) continue;

  const original = fs.readFileSync(filePath, "utf8");
  const updated = updateContent(original, lastVersion, nextVersion);

  // Avoid touching unchanged files to keep release commits clean.
  if (updated === original) continue;

  fs.writeFileSync(filePath, updated, "utf8");
  updatedFilesCount += 1;
}

console.log(
  `Updated tags module references from ${lastVersion} to ${nextVersion} in ${updatedFilesCount} file(s).`
);
