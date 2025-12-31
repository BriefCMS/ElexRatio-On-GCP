#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-briefcms.endpoints.able-decorator-477323-u6.cloud.goog}"
MP_ANNOTATION_KEY="com.googleapis.cloudmarketplace.product.service.name"
MP_ANNOTATION_VALUE="services/${SERVICE_NAME}"

PROJECT_ID="${PROJECT_ID:-able-decorator-477323-u6}"
REGION="${REGION:-us}"
REGISTRY="${REGISTRY:-${REGION}-docker.pkg.dev}"
REPO_PATH="${REPO_PATH:-gcr.io/elexratio}"

SERVICES=(
  "deployer"
  "kat-api"
  "ktaiflow-api"
  "kat-dynamic-portal"
  "kat-admin-studio"
  "ktaiflow-ui"
)

DEPLOYER_DOCKERFILE="${DEPLOYER_DOCKERFILE:-./deployer/Dockerfile}"
DEPLOYER_CONTEXT="${DEPLOYER_CONTEXT:-./deployer}"

DEPLOYER_VERSION="${DEPLOYER_VERSION:-2.2.0}"
if [[ "${1:-}" != "" ]]; then
  DEPLOYER_VERSION="$1"
fi
if ! [[ "$DEPLOYER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: DEPLOYER_VERSION must be semantic X.Y.Z (got: $DEPLOYER_VERSION)" >&2
  exit 1
fi

TAG_AMD64="${DEPLOYER_VERSION}-amd64"
SRC_TAG_AMD64="${SRC_TAG_AMD64:-2.2.0-amd64}"

die(){ echo "ERROR: $*" >&2; exit 1; }
require_cmd(){ command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

image_ref(){ echo "${REGISTRY}/${PROJECT_ID}/${REPO_PATH}/${1}:${2}"; }

manifest_media_type(){ crane manifest "$1" | jq -r '.mediaType // empty'; }

get_amd64_digest_from_index(){
  crane manifest "$1" \
    | jq -r '.manifests[] | select(.platform.os=="linux" and .platform.architecture=="amd64") | .digest' \
    | head -n 1
}

annotate_manifest(){
  crane mutate --annotation "${MP_ANNOTATION_KEY}=${MP_ANNOTATION_VALUE}" "$1"
}

verify_annotation(){
  local ref="$1"
  local actual
  actual="$(crane manifest "$ref" | jq -r --arg k "$MP_ANNOTATION_KEY" '.annotations[$k] // empty')"
  [[ "$actual" == "$MP_ANNOTATION_VALUE" ]] || die "Annotation missing/wrong on $ref (got: ${actual:-<missing>})"
}

# Ensure destination is single amd64 manifest and annotate
ensure_single_amd64_copy_and_annotate(){
  local src_ref="$1"
  local dst_ref="$2"

  local mt
  mt="$(manifest_media_type "$src_ref")"

  if [[ "$mt" == "application/vnd.oci.image.index.v1+json" || "$mt" == "application/vnd.docker.distribution.manifest.list.v2+json" ]]; then
    local amd64_digest
    amd64_digest="$(get_amd64_digest_from_index "$src_ref")"
    [[ -n "$amd64_digest" && "$amd64_digest" != "null" ]] || die "No linux/amd64 digest in index: $src_ref"
    local repo_no_tag="${src_ref%%:*}"
    crane cp "${repo_no_tag}@${amd64_digest}" "$dst_ref"
  else
    crane cp "$src_ref" "$dst_ref"
  fi

  annotate_manifest "$dst_ref"
  verify_annotation "$dst_ref"
}

# IMPORTANT CHANGE:
# Build deployer as single-arch into local docker (Docker schema2),
# then docker push so registry stores application/vnd.docker.distribution.manifest.v2+json.
build_push_deployer_docker_schema2(){
  local dst_ref="$1"

  [[ -f "$DEPLOYER_DOCKERFILE" ]] || return 1

  echo "Building deployer as single-arch (docker schema2 preference): $dst_ref"
  # --load loads into docker engine (single platform only). This avoids multi-arch indexes.
  docker buildx build \
    --platform linux/amd64 \
    -f "$DEPLOYER_DOCKERFILE" \
    -t "$dst_ref" \
    --load \
    "$DEPLOYER_CONTEXT"

  echo "Pushing deployer via docker push: $dst_ref"
  docker push "$dst_ref"

  # Sanity check: should be docker manifest v2, not an index
  local mt
  mt="$(manifest_media_type "$dst_ref")"
  if [[ "$mt" != "application/vnd.docker.distribution.manifest.v2+json" ]]; then
    echo "WARNING: mediaType is '$mt' (expected docker v2 manifest). Continuing, but Marketplace may still accept OCI too."
  fi

  annotate_manifest "$dst_ref"
  verify_annotation "$dst_ref"
}

# ---- Preconditions
require_cmd gcloud
require_cmd docker
require_cmd crane
require_cmd jq

gcloud auth configure-docker "${REGISTRY}" -q

# ---- Deployer
DEPLOYER_DST="$(image_ref "deployer" "$TAG_AMD64")"
if ! build_push_deployer_docker_schema2 "$DEPLOYER_DST"; then
  echo "Deployer Dockerfile not found; copying from ${SRC_TAG_AMD64}"
  DEPLOYER_SRC="$(image_ref "deployer" "$SRC_TAG_AMD64")"
  ensure_single_amd64_copy_and_annotate "$DEPLOYER_SRC" "$DEPLOYER_DST"
fi

# ---- App images (copy + annotate)
for svc in "${SERVICES[@]}"; do
  [[ "$svc" == "deployer" ]] && continue
  SRC="$(image_ref "$svc" "$SRC_TAG_AMD64")"
  DST="$(image_ref "$svc" "$TAG_AMD64")"
  ensure_single_amd64_copy_and_annotate "$SRC" "$DST"
done

echo "DONE. Update schema tags to: $TAG_AMD64"
