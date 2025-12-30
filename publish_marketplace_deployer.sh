#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# CONFIG (edit if needed)
# ----------------------------
PROJECT_ID="able-decorator-477323-u6"
AR_HOST="us-docker.pkg.dev"
AR_REPO="gcr.io"
IMAGE_PATH="elexratio/deployer"

# Pass VERSION like 2.2 (major.minor). Script will also push 2.2.0 by default.
VERSION_MM="${1:-2.2}"          # Example: 2.2
PATCH="${PATCH:-0}"             # default patch=0 => 2.2.0
DEPLOYER_DOCKERFILE="deployer/Dockerfile"
BUILD_CONTEXT="."

# Marketplace service annotation (from Google guidance)
MARKETPLACE_SERVICE_NAME="${MARKETPLACE_SERVICE_NAME:-services/briefcms.endpoints.${PROJECT_ID}.cloud.goog}"
ANNOTATION_KEY="com.googleapis.cloudmarketplace.product.service.name"

# ----------------------------
# DERIVED
# ----------------------------
IMAGE_BASE="${AR_HOST}/${PROJECT_ID}/${AR_REPO}/${IMAGE_PATH}"

TAG_MM="${VERSION_MM}"                  # 2.2
TAG_MMP="${VERSION_MM}.${PATCH}"        # 2.2.0

FULL_MM="${IMAGE_BASE}:${TAG_MM}"
FULL_MMP="${IMAGE_BASE}:${TAG_MMP}"

log(){ echo -e "\n[INFO] $*"; }
die(){ echo -e "\n[ERROR] $*" >&2; exit 1; }

# Validate version format major.minor
if [[ ! "${VERSION_MM}" =~ ^[0-9]+\.[0-9]+$ ]]; then
  die "VERSION must be major.minor like 2.2 (you passed: ${VERSION_MM})"
fi

command -v docker >/dev/null || die "docker not found"
command -v gcloud >/dev/null || die "gcloud not found"

# ----------------------------
# AUTH
# ----------------------------
log "Auth + Docker config for Artifact Registry (${AR_HOST})..."
gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud auth configure-docker "${AR_HOST}" --quiet >/dev/null

# ----------------------------
# Ensure buildx is ready
# ----------------------------
log "Ensuring docker buildx builder exists..."
if ! docker buildx inspect marketplace-builder >/dev/null 2>&1; then
  docker buildx create --name marketplace-builder --use >/dev/null
else
  docker buildx use marketplace-builder >/dev/null
fi

# (Optional) show builder
docker buildx inspect --bootstrap >/dev/null

# ----------------------------
# BUILD + PUSH (single command)
# ----------------------------
log "Building & pushing Marketplace deployer with tags:"
log "  ${FULL_MM}"
log "  ${FULL_MMP}"
log "Annotation:"
log "  ${ANNOTATION_KEY}=${MARKETPLACE_SERVICE_NAME}"

docker buildx build \
  --provenance=false \
  --annotation "${ANNOTATION_KEY}=${MARKETPLACE_SERVICE_NAME}" \
  -t "${FULL_MM}" \
  -t "${FULL_MMP}" \
  -f "${DEPLOYER_DOCKERFILE}" \
  "${BUILD_CONTEXT}" \
  --push

log "✅ Published:"
echo "${FULL_MM}"
echo "${FULL_MMP}"
