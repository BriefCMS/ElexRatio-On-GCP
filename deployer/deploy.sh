#!/bin/bash
set -euo pipefail

echo "===================================================="
echo " ElexRatio – Google Marketplace Deployer"
echo "===================================================="

#
# 1) Convert Marketplace config to params.env
#
echo "Checking for Marketplace configuration..."

# The Marketplace stores values in /data/values.yaml during deployer execution
if [[ -f /data/values.yaml ]]; then
  echo "Generating params.env from /data/values.yaml..."
  /bin/print_config.py \
    --xtype NAME \
    --values_mode raw \
    --output_file /data/NAME.env
  source /data/NAME.env
  
  /bin/print_config.py \
    --xtype NAMESPACE \
    --values_mode raw \
    --output_file /data/NAMESPACE.env
  source /data/NAMESPACE.env
  
  # Generate full params.env from all values
  /bin/print_config.py \
    --values_mode raw \
    --output_file /data/params.env
  
  echo "Loading params from /data/params.env"
  source /data/params.env

elif [[ -f /var/run/konlet/params ]]; then
  echo "Loading params from /var/run/konlet/params"
  source /var/run/konlet/params

else
  echo "❌ ERROR: No parameter file found"
  # Try to get values directly from environment as fallback
  if [[ -n "${APP_INSTANCE_NAME:-}" ]]; then
    echo "Using environment variables..."
  else
    ls -la /data/ || true
    ls -la /data/values/ || true
    exit 1
  fi
fi

# Debug: Show what parameters we have
echo " Instance : ${APP_INSTANCE_NAME:-NOT_SET}"
echo " Namespace: ${NAMESPACE:-NOT_SET}"
echo " Domain   : ${DOMAIN:-NOT_SET}"
echo "===================================================="

# Set defaults if not provided
export APP_INSTANCE_NAME="${APP_INSTANCE_NAME:-elexratio}"
export NAMESPACE="${NAMESPACE:-kat}"
export DOMAIN="${DOMAIN:-elexratio.example.com}"

# enable debug tracing after params load
set -x

#
# 2) Create namespace safely
#
echo "Ensuring namespace exists..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

#
# 3) Deploy components
#
deploy_component() {
  local name="$1"
  local path="/data/manifest/$name"

  echo "---- Deploying component: $name ----"

  if [[ ! -d "$path" ]]; then
    echo "Warning: Directory not found: $path"
    return
  fi

  shopt -s nullglob
  for file in "$path"/*.yaml "$path"/*.yml; do
    if [[ -f "$file" ]]; then
      echo "Applying: $file"
      envsubst < "$file" | kubectl apply -n "${NAMESPACE}" -f -
    fi
  done
  shopt -u nullglob
}

# Deploy all components
deploy_component "kat-api"
deploy_component "ktaiflow-api"
deploy_component "kat-admin-studio"
deploy_component "kat-dynamic-portal"
deploy_component "ktaiflow-ui"

#
# 4) Application CR (optional)
#
if [[ -f /data/manifest/app.yaml ]]; then
  echo "Applying Application CR..."
  envsubst < /data/manifest/app.yaml | kubectl apply -n "${NAMESPACE}" -f -
fi

#
# 5) Wait for deployments
#
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