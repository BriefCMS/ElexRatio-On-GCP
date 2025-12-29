#!/bin/bash
set -euo pipefail

echo "===================================================="
echo " ElexRatio – Google Marketplace Deployer"
echo "===================================================="

#
# 1) Convert values.yaml → params.env using Marketplace tool
#

if [[ -f /data/values.yaml ]]; then
  echo "Generating params.env from values.yaml..."
  /bin/print_config.py \
    --values_file /data/values.yaml \
    --schema_file /data/schema.yaml \
    --output_dir /data
fi

#
# 2) Load params from either source
#
if [[ -f /data/params.env ]]; then
  echo "Loading params from /data/params.env"
  source /data/params.env

elif [[ -f /var/run/konlet/params ]]; then
  echo "Loading params from /var/run/konlet/params"
  source /var/run/konlet/params

else
  echo "❌ ERROR: No parameter file found"
  ls -R /data || true
  exit 1
fi

echo " Instance : ${APP_INSTANCE_NAME}"
echo " Namespace: ${NAMESPACE}"
echo " Domain   : ${DOMAIN}"
echo "===================================================="

# enable debug tracing after params load
set -x

#
# 3) Create namespace safely
#
if [[ -f /data/namespace.yaml ]]; then
  kubectl apply -f <(envsubst < /data/namespace.yaml)
else
  kubectl create namespace "${NAMESPACE}" || true
fi

#
# 4) Deploy components
#
deploy_component() {
  local name="$1"
  local path="/data/$name"

  echo "---- Deploying component: $name ----"

  [[ -d "$path" ]] || return

  shopt -s nullglob
  for file in "$path"/*.yaml; do
    envsubst < "$file" | kubectl apply -n "${NAMESPACE}" -f -
  done
  shopt -u nullglob
}

deploy_component "kat-api"
deploy_component "ktaiflow-api"
deploy_component "kat-admin-studio"
deploy_component "kat-dynamic-portal"
deploy_component "ktaiflow-ui"

#
# 5) Application CR (optional)
#
if [[ -f /data/app.yaml ]]; then
  envsubst < /data/app.yaml | kubectl apply -n "${NAMESPACE}" -f -
fi

#
# 6) Wait for deployments — but don't fail job
#
DEPLOYMENTS=(
  "kat-api"
  "ktaiflow-api"
  "kat-admin-studio"
  "kat-dynamic-portal"
  "ktaiflow-ui"
)

for dep in "${DEPLOYMENTS[@]}"; do
  kubectl wait --for=condition=available --timeout=300s \
    deployment/"$dep" -n "${NAMESPACE}" || true
done

echo "===================================================="
echo " Deployment completed"
echo "===================================================="

# keep pod alive for debugging (remove later)
sleep 300
