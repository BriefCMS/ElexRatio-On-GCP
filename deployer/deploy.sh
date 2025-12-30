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

  # If kubectl cannot talk because kubeconfig is missing,
  # we are very likely in Producer Portal schema extraction.
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

  # Generate individual vars if needed
  /bin/print_config.py --xtype NAME --values_mode raw --output_file /data/NAME.env || true
  [[ -f /data/NAME.env ]] && source /data/NAME.env || true
