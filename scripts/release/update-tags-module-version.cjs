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
 * Replace all occurrences of release-pinned tags module references.
 */
function updateContent(content, fromVersion, toVersion) {
  return content
    .replaceAll(
      `//infrastructure/modules/tags?ref=${fromVersion}`,
      `//infrastructure/modules/tags?ref=${toVersion}`
    )
    .replaceAll(
      `//infrastructure/modules/tags | ${fromVersion} |`,
      `//infrastructure/modules/tags | ${toVersion} |`
    );
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
