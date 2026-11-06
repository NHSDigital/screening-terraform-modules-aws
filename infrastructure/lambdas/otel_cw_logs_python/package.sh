#!/usr/bin/env bash
# Build a Lambda deployment zip for otel_cw_logs_python.
#
# Usage:
#   ./package.sh [PYTHON_VERSION] [ARCHITECTURE]
#
# Arguments:
#   PYTHON_VERSION  Target Python version for pip wheels (default: 3.12)
#   ARCHITECTURE    Lambda CPU architecture: x86_64 or arm64 (default: arm64)
#
# Output:
#   ../../build/otel-cw-logs-python-py<version>-<architecture>.zip
#
# The script installs dependencies using --platform and --only-binary flags so
# that the resulting zip contains manylinux wheels matching the Lambda runtime,
# regardless of the build machine's own OS or CPU architecture.
set -euo pipefail

PYTHON_VERSION="${1:-3.12}"
ARCHITECTURE="${2:-arm64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${SCRIPT_DIR}/../../build"
WORK_DIR=$(mktemp -d)

cleanup() { rm -rf "${WORK_DIR}"; }
trap cleanup EXIT

# Map Lambda architecture names to pip platform tags.
# Lambda runs on Amazon Linux 2023 (AL2023), which uses glibc 2.34+.
case "${ARCHITECTURE}" in
  arm64)   PIP_PLATFORM="manylinux2014_aarch64" ;;
  x86_64)  PIP_PLATFORM="manylinux2014_x86_64" ;;
  *)
    echo "error: unsupported architecture '${ARCHITECTURE}' (use arm64 or x86_64)" >&2
    exit 1
    ;;
esac

PY_TAG="cp${PYTHON_VERSION//./}"  # e.g. cp312

echo "Building deployment zip for Python ${PYTHON_VERSION} / ${ARCHITECTURE}"
echo "  pip platform : ${PIP_PLATFORM}"
echo "  python tag   : ${PY_TAG}"

# Install dependencies into the working directory, forcing manylinux wheels for
# the target platform so compiled extensions like grpcio are compatible with the
# Lambda runtime.
pip install \
  --target "${WORK_DIR}" \
  --requirement "${SCRIPT_DIR}/requirements.txt" \
  --platform "${PIP_PLATFORM}" \
  --implementation cp \
  --python-version "${PYTHON_VERSION}" \
  --only-binary=:all: \
  --no-compile \
  --quiet

# Copy the Lambda handler source.
cp "${SCRIPT_DIR}/function.py" "${WORK_DIR}/"

# Remove any bytecode caches. pip's default __pycache__ compilation embeds
# non-deterministic bytes (subject to Python's hash randomization), which
# would otherwise change the zip hash on every build even with --no-compile
# guarding against it for wheels that ship their own caches.
find "${WORK_DIR}" -type d -name __pycache__ -exec rm -rf {} +

# Normalize modification times on everything we're about to zip, so the
# resulting archive hashes identically across builds regardless of when the
# source or dependencies were last touched on disk.
find "${WORK_DIR}" -exec touch -t 202001010000 {} +

# Build the zip.
mkdir -p "${BUILD_ROOT}"
ZIP_FILE="${BUILD_ROOT}/otel-cw-logs-python-py${PYTHON_VERSION}-${ARCHITECTURE}.zip"
rm -f "${ZIP_FILE}"
(cd "${WORK_DIR}" && zip -qr "${ZIP_FILE}" .)

echo "Created ${ZIP_FILE}"
