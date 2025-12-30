#!/usr/bin/env bash
set -euo pipefail

# ---------- CONFIG ----------
PROJECT_ID="able-decorator-477323-u6"
REGION="us"
REPO_BASE="us-docker.pkg.dev/${PROJECT_ID}/gcr.io/elexratio"

# Marketplace expected service name (MUST match Producer Portal)
EXPECTED_SERVICE="services/briefcms.endpoints.able-decorator-477323-u6.cloud.goog"

# Versions
DEPLOYER_TAG="${DEPLOYER_TAG:-2.2.0-test1}"   # base tag (no arch suffix)
APP_TAG="${APP_TAG:-2.0.0}"                  # base tag (no arch suffix)
ARCH_SUFFIX="amd64"
PLATFORM="linux/amd64"

# Images to process (repo names)
DEPLOYER_IMAGE="${REPO_BASE}/deployer"
APP_IMAGES=(
  "kat-api"
  "ktaiflow-api"
  "kat-dynamic-portal"
  "kat-admin-studio"
  "ktaiflow-ui"
)

# Where your deployer Dockerfile is
DEPLOYER_DOCKERFILE="deployer/Dockerfile"
# Build context must be repo root (.)
BUILD_CONTEXT="."

# schema file
SCHEMA_PATH="deploy/schema.yaml"   # adjust if yours is elsewhere
# ---------- END CONFIG ----------


need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1"; exit 1; }; }
need docker
need crane
need jq

echo "==> Using:"
echo "    REPO_BASE=${REPO_BASE}"
echo "    EXPECTED_SERVICE=${EXPECTED_SERVICE}"
echo "    DEPLOYER_TAG=${DEPLOYER_TAG}"
echo "    APP_TAG=${APP_TAG}"
echo

# ---------- Helper: annotate a single-arch tag ----------
annotate_image() {
  local src="$1"   # e.g. .../kat-api:2.0.0-amd64
  local dst="$2"   # e.g. .../kat-api:2.0.0-amd64-mp

  echo "==> Ensure single-arch & create final tag: $dst"
  crane copy --platform "${PLATFORM}" "${src}" "${dst}"

  echo "==> Apply Marketplace annotation to: $dst"
  crane mutate --annotation "com.googleapis.cloudmarketplace.product.service.name=${EXPECTED_SERVICE}" "${dst}"

  local val
  val=$(docker buildx imagetools inspect "${dst}" --raw | jq -r '.annotations["com.googleapis.cloudmarketplace.product.service.name"]')
  if [[ "$val" != "${EXPECTED_SERVICE}" ]]; then
    echo "ERROR: Annotation mismatch on ${dst}"
    echo "Got:  ${val}"
    echo "Want: ${EXPECTED_SERVICE}"
    exit 1
  fi
  echo "    OK annotation: $val"
  echo
}

# ---------- 1) Build & push deployer image (amd64) ----------
DEPLOYER_TAG_ARCH="${DEPLOYER_TAG}-${ARCH_SUFFIX}"
DEPLOYER_TAG_MP="${DEPLOYER_TAG_ARCH}-mp"

echo "==> Build & push deployer: ${DEPLOYER_IMAGE}:${DEPLOYER_TAG_ARCH}"
docker buildx build --platform "${PLATFORM}" \
  -f "${DEPLOYER_DOCKERFILE}" \
  -t "${DEPLOYER_IMAGE}:${DEPLOYER_TAG_ARCH}" \
  --push "${BUILD_CONTEXT}"

# ---------- 2) Annotate deployer into final -mp tag ----------
annotate_image "${DEPLOYER_IMAGE}:${DEPLOYER_TAG_ARCH}" "${DEPLOYER_IMAGE}:${DEPLOYER_TAG_MP}"

# ---------- 3) Annotate app images into final -mp tags ----------
for name in "${APP_IMAGES[@]}"; do
  src="${REPO_BASE}/${name}:${APP_TAG}-${ARCH_SUFFIX}"
  dst="${REPO_BASE}/${name}:${APP_TAG}-${ARCH_SUFFIX}-mp"
  annotate_image "${src}" "${dst}"
done

# ---------- 4) Patch schema defaults to point to -mp tags ----------
echo "==> Update schema defaults to use -mp tags: ${SCHEMA_PATH}"

# deployer tag (both places if present)
sed -i \
  -e "s/default: \"${DEPLOYER_TAG_ARCH}\"/default: \"${DEPLOYER_TAG_MP}\"/g" \
  -e "s/default: \"${DEPLOYER_TAG}\"/default: \"${DEPLOYER_TAG_MP}\"/g" \
  "${SCHEMA_PATH}" || true

# app tags (both places if present)
for name in "${APP_IMAGES[@]}"; do
  sed -i \
    -e "s/default: \"${APP_TAG}-${ARCH_SUFFIX}\"/default: \"${APP_TAG}-${ARCH_SUFFIX}-mp\"/g" \
    "${SCHEMA_PATH}" || true
done

echo "==> Done updating schema. (Please review git diff)"
echo

# ---------- 5) Print final tags to use for verify ----------
echo "==> Use this deployer image for verify:"
echo "export DEPLOYER_IMAGE=\"${DEPLOYER_IMAGE}:${DEPLOYER_TAG_MP}\""
echo
echo "==> Next: run /scripts/verify with DEPLOYER_IMAGE above"
