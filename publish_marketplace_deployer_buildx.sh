#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="able-decorator-477323-u6"
REPO_BASE="us-docker.pkg.dev/${PROJECT_ID}/gcr.io/elexratio"
EXPECTED_SERVICE="services/briefcms.endpoints.able-decorator-477323-u6.cloud.goog"

# MUST be pure semver (MAJOR.MINOR.PATCH)
DEPLOYER_VERSION="${DEPLOYER_VERSION:-2.2.0}"

PLATFORM="linux/amd64"
ARCH="amd64"

DEPLOYER_IMAGE="${REPO_BASE}/deployer"
RAW_TAG="${DEPLOYER_VERSION}-${ARCH}"     # build tag
FINAL_TAG="${DEPLOYER_VERSION}"           # marketplace tag (pure semver)

DOCKERFILE_PATH="deployer/Dockerfile"
BUILD_CONTEXT="."

for tool in docker crane jq git; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing tool: $tool"; exit 1; }
done

if [[ "${1:-}" == "--pull" ]]; then
  git pull
fi

echo "Building: ${DEPLOYER_IMAGE}:${RAW_TAG}"
docker buildx build --platform "${PLATFORM}" \
  -f "${DOCKERFILE_PATH}" \
  -t "${DEPLOYER_IMAGE}:${RAW_TAG}" \
  --push "${BUILD_CONTEXT}"

echo "Copying to final semver tag: ${DEPLOYER_IMAGE}:${FINAL_TAG}"
crane copy --platform "${PLATFORM}" \
  "${DEPLOYER_IMAGE}:${RAW_TAG}" \
  "${DEPLOYER_IMAGE}:${FINAL_TAG}"

echo "Annotating final tag: ${DEPLOYER_IMAGE}:${FINAL_TAG}"
crane mutate \
  --annotation "com.googleapis.cloudmarketplace.product.service.name=${EXPECTED_SERVICE}" \
  "${DEPLOYER_IMAGE}:${FINAL_TAG}"

echo "Verifying annotation..."
val=$(docker buildx imagetools inspect "${DEPLOYER_IMAGE}:${FINAL_TAG}" --raw \
  | jq -r '.annotations["com.googleapis.cloudmarketplace.product.service.name"]')

if [[ "$val" != "$EXPECTED_SERVICE" ]]; then
  echo "ERROR: Annotation mismatch"
  echo "Expected: $EXPECTED_SERVICE"
  echo "Found   : $val"
  exit 1
fi

echo "SUCCESS ✅"
echo "Use this for verify:"
echo "export DEPLOYER_IMAGE=\"${DEPLOYER_IMAGE}:${FINAL_TAG}\""
