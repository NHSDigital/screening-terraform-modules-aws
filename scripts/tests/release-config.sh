#!/bin/bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Guardrail test: ensure semantic-release/git assets include the file types
# that the release updater can modify. This prevents updates being generated
# in prepare but silently omitted from the release commit.
node <<'EOF'
const fs = require("node:fs");

const releasercPath = ".releaserc.json";
const requiredAssets = [
  "CHANGELOG.md",
  "infrastructure/modules/**/README.md",
  "infrastructure/modules/**/context.tf",
  "infrastructure/modules/**/*.tf"
];

const config = JSON.parse(fs.readFileSync(releasercPath, "utf8"));
const plugins = Array.isArray(config.plugins) ? config.plugins : [];

const gitPlugin = plugins.find(
  (entry) => Array.isArray(entry) && entry[0] === "@semantic-release/git"
);

if (!gitPlugin) {
  console.error("release-config test failed: @semantic-release/git plugin not found in .releaserc.json");
  process.exit(1);
}

const gitOptions = gitPlugin[1] || {};
const assets = Array.isArray(gitOptions.assets) ? gitOptions.assets : [];
const missing = requiredAssets.filter((asset) => !assets.includes(asset));

if (missing.length > 0) {
  console.error("release-config test failed: missing required @semantic-release/git assets:");
  for (const asset of missing) {
    console.error(`- ${asset}`);
  }
  process.exit(1);
}

console.log("release-config test passed");
EOF
