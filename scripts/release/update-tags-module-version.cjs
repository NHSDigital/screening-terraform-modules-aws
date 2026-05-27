#!/usr/bin/env node

/**
 * Update local module source version references between semantic-release versions.
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

const fs = require("node:fs");
const path = require("node:path");

const MODULES_ROOT = path.join("infrastructure", "modules");

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
 * Return true for files that may contain version-pinned local module references:
 * - Terraform source files (.tf)
 * - Module README files (README.md / readme.md)
 */
function isTargetFile(filePath) {
  const fileExt = path.extname(filePath).toLowerCase();
  const baseName = path.basename(filePath).toLowerCase();

  return fileExt === ".tf" || baseName === "readme.md";
}

/**
 * Escape user-provided values before embedding into a regular expression.
 */
function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Replace all release-pinned local module source references, for example:
 * git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/<any-module>?ref=<version>
 * and README table rows such as:
 * | git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/<any-module> | <version> |
 */
function updateContent(content, fromVersion, toVersion) {
  let updated = content;

  for (const pair of buildVersionPairs(fromVersion, toVersion)) {
    const sourcePrefixPattern = String.raw`(git::https://github\.com/NHSDigital/screening-terraform-modules-aws\.git//infrastructure/modules/[^?\s"']+\?ref=)`;
    const readmePrefixPattern = String.raw`(\|\s*git::https://github\.com/NHSDigital/screening-terraform-modules-aws\.git//infrastructure/modules/[^|\s]+\s*\|\s*)`;
    const readmeSuffixPattern = String.raw`(\s*\|)`;

    const sourcePattern = new RegExp(
      sourcePrefixPattern + escapeRegex(pair.from),
      "g"
    );

    const readmeTablePattern = new RegExp(
      readmePrefixPattern + escapeRegex(pair.from) + readmeSuffixPattern,
      "g"
    );

    updated = updated
      .replace(sourcePattern, `$1${pair.to}`)
      .replace(readmeTablePattern, `$1${pair.to}$2`);
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
  if (!isTargetFile(filePath)) continue;

  const original = fs.readFileSync(filePath, "utf8");
  const updated = updateContent(original, lastVersion, nextVersion);

  // Avoid touching unchanged files to keep release commits clean.
  if (updated === original) continue;

  fs.writeFileSync(filePath, updated, "utf8");
  updatedFilesCount += 1;
}

console.log(
  `Updated local module source references from ${lastVersion} to ${nextVersion} in ${updatedFilesCount} file(s).`
);
