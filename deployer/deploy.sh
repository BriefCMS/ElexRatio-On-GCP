#!/bin/bash
set -euo pipefail

echo "===================================================="
echo " ElexRatio – Google Marketplace Deployer"
echo "===================================================="

# -----------------------------------------------------
# Helper: detect "schema extraction" / non-cluster mode
# -----------------------------------------------------
is_schema_extract_mode() {
  # If explicitly requested
  if [[ "${EXTRACT_SCHEMA:-}" == "true" ]]; then
    return 0
  fi

  # If kubeconfig + SA token missing, likely schema extraction phase
  if [[ ! -f "${KUBECONFIG:-/root/.kube/config}" && ! -f "/var/run/secrets/kubernetes.io/serviceaccount/token" ]]; then
    return 0
  fi

  # If kubectl is not present (should be present in base image, but safe)
  command -v kubectl >/dev/null 2>&1 || return 0

  return 1
}

# -----------------------------------------------------
# 1) Convert Marketplace config to params.env (best effort)
# -----------------------------------------------------
echo "Checking for Marketplace configuration..."

if [[ -f /data/values.yaml ]]; then
  echo "Generating params.env from /data/values.yaml..."

  # Generate individual vars if needed (safe if missing)
  /bin/print_config.py --xtype NAME --values_mode raw --output_file /data/NAME.env || true
  [[ -f /data/NAME.env ]] && source /data/NAME.env || true

  /bin/print_config.py --xtype NAMESPACE --values_mode raw --output_file /data/NAMESPACE.env || true
  [[ -f /data/NAMESPACE.env ]] && source /data/NAMESPACE.env || true

  # Generate full params.env from all values
  /bin/print_config.py --values_mode raw --output_file /data/params.env

  echo "Loading params from /data/params.env"
  source /data/params.env

elif [[ -f /var/run/konlet/params ]]; then
  echo "Loading params from /var/run/konlet/params"
  source /var/run/konlet/params

else
  echo "No parameter file found. Continuing with defaults/environment."
fi

# Debug: Show key parameters we have
echo " Instance : ${APP_INSTANCE_NAME:-NOT_SET}"
echo " Namespace: ${NAMESPACE:-NOT_SET}"
echo " Domain   : ${DOMAIN:-NOT_SET}"
echo "===================================================="

# Defaults
export APP_INSTANCE_NAME="${APP_INSTANCE_NAME:-elexratio}"
export NAMESPACE="${NAMESPACE:-kat}"
export DOMAIN="${DOMAIN:-elexratio.example.com}"
export SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-default}"

# -----------------------------------------------------
# Early exit for schema extraction
# -----------------------------------------------------
if is_schema_extract_mode; then
  echo "[INFO] Schema-extraction/config-only mode detected."
  echo "[INFO] Skipping kubectl operations and exiting 0."
  exit 0
fi

# enable debug tracing after params load
set -x

# -----------------------------------------------------
# 2) Create namespace safely
# -----------------------------------------------------
echo "Ensuring namespace exists..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------
# 3) Deploy components (OPTION A: flat manifest files)
#    Looks for: /data/manifest/<service>-*.yaml
#    Example:  /data/manifest/kat-api-deployment.yaml
# -----------------------------------------------------
MANIFEST_DIR="/data/manifest"

deploy_component() {
  local name="$1"
  local path="${MANIFEST_DIR}"

  echo "---- Deploying component: $name ----"

  if [[ ! -d "${path}" ]]; then
    echo "Warning: Directory not found: ${path}"
    return
  fi

  shopt -s nullglob
  local files=( "${path}/${name}-"*.yaml "${path}/${name}-"*.yml )
  if (( ${#files[@]} == 0 )); then
    echo "Warning: No manifest files found for ${name} in ${path} (expected ${name}-*.yaml)"
    shopt -u nullglob
    return
  fi

  for file in "${files[@]}"; do
    echo "Applying: $file"
    envsubst < "$file" | kubectl apply -n "${NAMESPACE}" -f -
  done
  shopt -u nullglob
}

# Deploy all components
deploy_component "kat-api"
deploy_component "ktaiflow-api"
deploy_component "kat-admin-studio"
deploy_component "kat-dynamic-portal"
deploy_component "ktaiflow-ui"

# -----------------------------------------------------
# 4) Application CR (optional)
# -----------------------------------------------------
if [[ -f "${MANIFEST_DIR}/app.yaml" ]]; then
  echo "Applying Application CR..."
  envsubst < "${MANIFEST_DIR}/app.yaml" | kubectl apply -n "${NAMESPACE}" -f -
fi

# -----------------------------------------------------
# 5) Wait for deployments
# -----------------------------------------------------
echo "Waiting for deployments to become available..."
DEPLOYMENTS=(
  "kat-api"
  "ktaiflow-api"
  "kat-admin-studio"
  "kat-dynamic-portal"
  "ktaiflow-ui"
)

for dep in "${DEPLOYMENTS[@]}"; do
  echo "Checking deployment: $dep"
  if kubectl get deployment "$dep" -n "${NAMESPACE}" >/dev/null 2>&1; then
    kubectl wait --for=condition=available --timeout=300s \
      deployment/"$dep" -n "${NAMESPACE}" || echo "Warning: $dep not ready"
  else
    echo "Warning: Deployment $dep not found"
  fi
done

echo "===================================================="
echo "✅ Deployment completed successfully"
echo "===================================================="
