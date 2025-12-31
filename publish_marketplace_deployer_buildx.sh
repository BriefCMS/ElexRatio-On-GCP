#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# publish_marketplace_deployer.sh
#
# What it does:
# 1) Enforces Semantic Versioning (X.Y.Z)
# 2) Publishes/retags images with consistent tagging (X.Y.Z-amd64)
# 3) Ensures images are SINGLE-MANIFEST linux/amd64 (not an index)
# 4) Adds required Cloud Marketplace annotation on each image manifest
#
# Usage:
#   ./publish_marketplace_deployer.sh 2.2.1
#   DEPLOYER_VERSION=2.2.1 SRC_TAG_AMD64=2.2.0-amd64 ./publish_marketplace_deployer.sh
#
# Notes:
# - If your app images don't have Dockerfiles, this script "copies" from an existing
#   known-good tag (SRC_TAG_AMD64) to the new semantic tag and annotates.
# - Deployer image can be built from ./deployer/Dockerfile (if present), else it will also be copied.
# ============================================================

# -----------------------------
# REQUIRED: set your Marketplace Service Name here
# -----------------------------
SERVICE_NAME="${SERVICE_NAME:-briefcms.endpoints.able-decorator-477323-u6.cloud.goog}"
MP_ANNOTATION_KEY="com.googleapis.cloudmarketplace.product.service.name"
MP_ANNOTATION_VALUE="services/${SERVICE_NAME}"

# -----------------------------
# Registry / project settings
# -----------------------------
PROJECT_ID="${PROJECT_ID:-able-decorator-477323-u6}"
REGION="${REGION:-us}"
REGISTRY="${REGISTRY:-${REGION}-docker.pkg.dev}"
REPO_PATH="${REPO_PATH:-gcr.io/elexratio}"   # path under Artifact Registry project

# Services in your schema
SERVICES=(
  "deployer"
  "kat-api"
  "ktaiflow-api"
  "kat-dynamic-portal"
  "kat-admin-studio"
  "ktaiflow-ui"
)

# Where deployer Dockerfile/context is (if you want to build deployer)
DEPLOYER_DOCKERFILE="${DEPLOYER_DOCKERFILE:-./deployer/Dockerfile}"
DEPLOYER_CONTEXT="${DEPLOYER_CONTEXT:-./deployer}"

# -----------------------------
# Versioning (Semantic Versioning X.Y.Z)
# -----------------------------
DEPLOYER_VERSION="${DEPLOYER_VERSION:-2.2.0}"
if [[ "${1:-}" != "" ]]; then
  DEPLOYER_VERSION="$1"
fi
if ! [[ "$DEPLOYER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: DEPLOYER_VERSION must be semantic X.Y.Z (got: $DEPLOYER_VERSION)" >&2
  exit 1
fi

# Tag convention
TAG_AMD64="${DEPLOYER_VERSION}-amd64"

# Source tag to copy from for app images (and deployer if no Dockerfile build).
# This must be an EXISTING tag in your registry that represents a working amd64 image or index.
SRC_TAG_AMD64="${SRC_TAG_AMD64:-2.2.0-amd64}"

# -----------------------------
# Helpers
# -----------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

image_ref() {
  local name="$1"
  local tag="$2"
  echo "${REGISTRY}/${PROJECT_ID}/${REPO_PATH}/${name}:${tag}"
}

manifest_media_type() {
  local ref="$1"
  crane manifest "$ref" | jq -r '.mediaType // empty'
}

get_amd64_digest_from_index() {
  local ref="$1"
  crane manifest "$ref" \
    | jq -r '.manifests[] | select(.platform.os=="linux" and .platform.architecture=="amd64") | .digest' \
    | head -n 1
}

annotate_manifest() {
  local ref="$1"
  echo "Annotating: $ref"
  crane mutate --annotation "${MP_ANNOTATION_KEY}=${MP_ANNOTATION_VALUE}" "$ref"
}

verify_annotation() {
  local ref="$1"
  local actual
  actual="$(crane manifest "$ref" | jq -r --arg k "$MP_ANNOTATION_KEY" '.annotations[$k] // empty')"
  if [[ "$actual" != "$MP_ANNOTATION_VALUE" ]]; then
    echo "❌ Annotation verification failed for: $ref"
    echo "Expected: $MP_ANNOTATION_VALUE"
    echo "Actual:   ${actual:-<missing>}"
    echo "All annotations:"
    crane manifest "$ref" | jq '.annotations'
    exit 1
  fi
  echo "✅ Annotation verified: $ref"
}

# Copy src -> dst ensuring dst becomes a SINGLE linux/amd64 manifest (not an index), then annotate.
ensure_single_amd64_copy_and_annotate() {
  local src_ref="$1"
  local dst_ref="$2"

  local mt
  mt="$(manifest_media_type "$src_ref")"

  if [[ "$mt" == "application/vnd.oci.image.index.v1+json" || "$mt" == "application/vnd.docker.distribution.manifest.list.v2+json" ]]; then
    echo "Source is an INDEX. Extracting linux/amd64 digest from: $src_ref"
    local amd64_digest
    amd64_digest="$(get_amd64_digest_from_index "$src_ref")"
    [[ -n "$amd64_digest" && "$amd64_digest" != "null" ]] || die "Could not find linux/amd64 digest in index: $src_ref"

    local repo_no_tag="${src_ref%%:*}"  # safe because src_ref is repo:tag
    echo "Copying amd64 digest -> single manifest:"
    echo "  ${repo_no_tag}@${amd64_digest} -> $dst_ref"
    crane cp "${repo_no_tag}@${amd64_digest}" "$dst_ref"
  else
    echo "Source is a single manifest. Copying:"
    echo "  $src_ref -> $dst_ref"
    crane cp "$src_ref" "$dst_ref"
  fi

  # Now annotate the destination (should be single manifest)
  annotate_manifest "$dst_ref"
  verify_annotation "$dst_ref"
}

# Build & push deployer as SINGLE linux/amd64, then annotate.
build_push_deployer_if_possible() {
  local dst_ref="$1"

  if [[ -f "$DEPLOYER_DOCKERFILE" ]]; then
    echo "Building deployer (linux/amd64 only): $dst_ref"
    docker buildx build \
      --platform linux/amd64 \
      -f "$DEPLOYER_DOCKERFILE" \
      -t "$dst_ref" \
      --push \
      "$DEPLOYER_CONTEXT"

    # If for any reason it still ends up as an index, normalize by digest-copy to itself and annotate.
    local mt
    mt="$(manifest_media_type "$dst_ref")"
    if [[ "$mt" == "application/vnd.oci.image.index.v1+json" || "$mt" == "application/vnd.docker.distribution.manifest.list.v2+json" ]]; then
      echo "Deployer tag became an INDEX (unexpected for single platform). Normalizing..."
      local amd64_digest
      amd64_digest="$(get_amd64_digest_from_index "$dst_ref")"
      [[ -n "$amd64_digest" && "$amd64_digest" != "null" ]] || die "Could not find linux/amd64 digest for deployer index: $dst_ref"
      local repo_no_tag="${dst_ref%%:*}"
      crane cp "${repo_no_tag}@${amd64_digest}" "$dst_ref"
    fi

    annotate_manifest "$dst_ref"
    verify_annotation "$dst_ref"
    return 0
  fi

  echo "WARNING: Deployer Dockerfile not found at $DEPLOYER_DOCKERFILE"
  echo "Will COPY deployer from existing source tag: ${SRC_TAG_AMD64}"
  return 1
}

# -----------------------------
# Preconditions
# -----------------------------
require_cmd gcloud
require_cmd docker
require_cmd crane
require_cmd jq

echo "============================================================"
echo "Publishing Marketplace images with:"
echo "  DEPLOYER_VERSION : $DEPLOYER_VERSION"
echo "  TAG_AMD64        : $TAG_AMD64"
echo "  SRC_TAG_AMD64    : $SRC_TAG_AMD64"
echo "  Registry         : $REGISTRY"
echo "  Project          : $PROJECT_ID"
echo "  Repo path        : $REPO_PATH"
echo "  Annotation       : ${MP_ANNOTATION_KEY}=${
