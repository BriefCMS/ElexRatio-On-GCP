#!/bin/bash
set -euo pipefail

# Load Marketplace-injected values + image mappings
source /data/params.env

echo "===================================================="
echo " ElexRatio – Google Marketplace manifest dataer"
echo " Namespace : ${NAMESPACE}"
echo " ServiceAccount : ${SERVICE_ACCOUNT}"
echo " Domain : ${DOMAIN}"
echo "===================================================="

echo "Deployer image: ${DEPLOYER_IMAGE}"

echo "Creating namespace (idempotent)..."
kubectl apply -f <(envsubst < /data/namespace.yaml)

echo "Waiting for namespace to become active..."
kubectl wait --for=condition=Established --timeout=30s namespace "${NAMESPACE}" || true

echo "dataing kat-api..."
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-api/backendconfig.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-api/service.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-api/managed-cert.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-api/ingress.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-api/datament.yaml)


echo "dataing ktaiflow-api..."
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-api/backendconfig.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-api/service.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-api/managed-cert.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-api/ingress.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-api/datament.yaml)


echo "dataing kat-admin-studio..."
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-admin-studio/service.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-admin-studio/managed-cert.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-admin-studio/ingress.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-admin-studio/datament.yaml)


echo "dataing kat-dynamic-portal..."
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-dynamic-portal/service.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-dynamic-portal/managed-cert.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-dynamic-portal/ingress.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/kat-dynamic-portal/datament.yaml)


echo "dataing ktaiflow-ui..."
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-ui/service.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-ui/managed-cert.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-ui/ingress.yaml)
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/ktaiflow-ui/datament.yaml)


echo "Creating Application CR..."
kubectl apply -n "${NAMESPACE}" -f <(envsubst < /data/app.yaml)

echo "===================================================="
echo " datament completed successfully."
echo "===================================================="
