#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Build + Push Marketplace Deployer Image (WSL)
# Target:
# us-docker.pkg.dev/able-decorator-477323-u6/gcr.io/elexratio/deployer:<tag>
# ============================================================

PROJECT_ID="able-decorator-477323-u6"
AR_HOST="us-docker.pkg.dev"
AR_REPO="gcr.io"
IMAGE_PATH="elexratio/deployer"
TAG="${1:-v1}"

FULL_IMAGE="${AR_HOST}/${PROJECT_ID}/${AR_REPO}/${IMAGE_PATH}:${TAG}"

# Expected repo files/folders (based on your Dockerfile)
DEPLOYER_DOCKERFILE="deployer/Dockerfile"
DEPLOYER_SCRIPTS=("deployer/deploy.sh" "deployer/deploy_with_tests.sh")
DEPLOY_DIR="deploy"
DOCS_DIR="docs"
SCHEMA_IN_DEPLOY="deploy/schema.yaml"

SERVICES=(
  "kat-admin-studio"
  "kat-api"
  "kat-dynamic-portal"
  "ktaiflow-api"
  "ktaiflow-ui"
)

# manifests expected inside each deploy/<service> folder
MANIFEST_RULES=(
  "deployment.yaml"
  "service.yaml"
  "ingres.yaml|ingress.yaml"
  "maanged-cert.yaml|managed-cert.yaml|managed_cert.yaml"
)

log(){ echo -e "\n[INFO] $*"; }
warn(){ echo -e "\n[WARN] $*" >&2; }
die(){ echo -e "\n[ERROR] $*" >&2; exit 1; }

require_cmd(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

# -------- Prechecks --------
require_cmd docker
require_cmd gcloud

log "Validating repo structure required by deployer/Dockerfile..."

[[ -f "${DEPLOYER_DOCKERFILE}" ]] || die "Missing ${DEPLOYER_DOCKERFILE}"
[[ -d "${DEPLOY_DIR}" ]] || die "Missing ${DEPLOY_DIR}/"
[[ -d "${DOCS_DIR}" ]] || warn "Missing ${DOCS_DIR}/ (Dockerfile copies docs/ into image; build may fail if absent)"

for f in "${DEPLOYER_SCRIPTS[@]}"; do
  [[ -f "$f" ]] || die "Missing $f"
done

[[ -f "${SCHEMA_IN_DEPLOY}" ]] || warn "Missing ${SCHEMA_IN_DEPLOY} (Dockerfile copies deploy/schema.yaml; build will fail if absent)"

# Validate 5 service folders + manifests
for svc in "${SERVICES[@]}"; do
  svc_dir="deploy/${svc}"
  [[ -d "${svc_dir}" ]] || die "Missing service folder: ${svc_dir}"

  for rule in "${MANIFEST_RULES[@]}"; do
    IFS='|' read -r -a candidates <<< "$rule"
    found=false
    for mf in "${candidates[@]}"; do
      if [[ -f "${svc_dir}/${mf}" ]]; then
        found=true
        break
      fi
    done
    if [[ "${found}" == "false" ]]; then
      warn "In ${svc_dir}, missing manifest: expected one of [${rule}]"
    fi
  done
done

log "Repo structure looks OK."

# -------- Auth for Artifact Registry --------
log "Authenticating + configuring Docker for ${AR_HOST}..."

# Interactive by default (works in WSL)
# For CI: export GOOGLE_APPLICATION_CREDENTIALS=/path/key.json
if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" && -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
  log "Using service account key: ${GOOGLE_APPLICATION_CREDENTIALS}"
  gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}" >/dev/null
else
  gcloud auth login >/dev/null
fi

gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud auth configure-docker "${AR_HOST}" --quiet >/dev/null

# -------- Build + Push --------
log "Building deployer image:"
log "  ${FULL_IMAGE}"

# IMPORTANT: build context is repo root "."
docker build -f "${DEPLOYER_DOCKERFILE}" -t "${FULL_IMAGE}" .

log "Pushing deployer image..."
docker push "${FULL_IMAGE}"

log "✅ Published deployer image to Partner Portal registry:"
echo "${FULL_IMAGE}"
