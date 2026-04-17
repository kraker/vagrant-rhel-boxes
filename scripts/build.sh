#!/usr/bin/env bash
# Build a RHEL Vagrant box for one (version, provider) combination.
#
# Usage: scripts/build.sh <version> <provider>
#
#   version   RHEL version (e.g. rhel-10.0)
#   provider  vagrant-libvirt | vagrant-virtualbox
#
# Output box lands in build/<version>-<provider>.box
#
# Prerequisites:
#   - image-builder installed (Fedora: dnf install image-builder osbuild osbuild-tools)
#   - subscription-manager registered to a Red Hat account with RHEL entitlements
#   - sudo access (image-builder requires root for nspawn / loop devices)
set -euo pipefail

VERSION="${1:-rhel-10.0}"
PROVIDER="${2:-vagrant-libvirt}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BLUEPRINT="${REPO_ROOT}/blueprints/${VERSION%%.*}.toml"
OUTPUT_DIR="${REPO_ROOT}/build/${VERSION}-${PROVIDER}"

if [ ! -f "${BLUEPRINT}" ]; then
    echo "ERROR: blueprint not found: ${BLUEPRINT}" >&2
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"

echo "==> Building ${VERSION} ${PROVIDER}"
echo "    Blueprint: ${BLUEPRINT}"
echo "    Output:    ${OUTPUT_DIR}"
echo

sudo image-builder build \
    --distro "${VERSION}" \
    --blueprint "${BLUEPRINT}" \
    --output-dir "${OUTPUT_DIR}" \
    "${PROVIDER}"

echo
echo "==> Done. Artifacts in ${OUTPUT_DIR}:"
ls -la "${OUTPUT_DIR}"
