#!/bin/bash
set -e

source /deploy/params.env

echo "Creating namespace..."
kubectl apply -f <(envsubst < /deploy/namespace.yaml)

echo "Deploying kat-api..."
kubectl apply -f <(envsubst < /deploy/kat-api/backendconfig.yaml)
kubectl apply -f <(envsubst < /deploy/kat-api/service.yaml)
kubectl apply -f <(envsubst < /deploy/kat-api/managed-cert.yaml)
kubectl apply -f <(envsubst < /deploy/kat-api/ingress.yaml)
kubectl apply -f <(envsubst < /deploy/kat-api/deployment.yaml)

echo "Deploying ktaiflow-api..."
kubectl apply -f <(envsubst < /deploy/ktaiflow-api/backendconfig.yaml)
kubectl apply -f <(envsubst < /deploy/ktaiflow-api/service.yaml)
kubectl apply -f <(envsubst < /deploy/ktaiflow-api/managed-cert.yaml)
kubectl apply -f <(envsubst < /deploy/ktaiflow-api/ingress.yaml)
kubectl apply -f <(envsubst < /deploy/ktaiflow-api/deployment.yaml)

echo "Deploying kat-admin-studio..."
kubectl apply -f <(envsubst < /deploy/kat-admin-studio/service.yaml)
kubectl apply -f <(envsubst < /deploy/kat-admin-studio/managed-cert.yaml)
kubectl apply -f <(envsubst < /deploy/kat-admin-studio/ingress.yaml)
kubectl apply -f <(envsubst < /deploy/kat-admin-studio/deployment.yaml)

echo "Deploying kat-dynamic-portal..."
kubectl apply -f <(envsubst < /deploy/kat-dynamic-portal/service.yaml)
kubectl apply -f <(envsubst < /deploy/kat-dynamic-portal/managed-cert.yaml)
kubectl apply -f <(envsubst < /deploy/kat-dynamic-portal/ingress.yaml)
kubectl apply -f <(envsubst < /deploy/kat-dynamic-portal/deployment.yaml)

echo "Deploying ktaiflow-ui..."
kubectl apply -f <(envsubst < /deploy/ktaiflow-ui/service.yaml)
kubectl apply -f <(envsubst < /deploy/ktaiflow-ui/managed-cert.yaml)
kubectl apply -f <(envsubst < /deploy/ktaiflow-ui/ingress.yaml)
kubectl apply -f <(envsubst < /deploy/ktaiflow-ui/deployment.yaml)

echo "Creating Application CR..."
kubectl apply -f <(envsubst < /deploy/app.yaml)

echo "Deployment completed successfully."
