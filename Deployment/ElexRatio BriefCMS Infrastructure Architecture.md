# ElexRatio BriefCMS – Infrastructure Architecture

## Overview

**ElexRatio BriefCMS** is a production-grade legal case management system with AI-powered document processing capabilities designed to meet enterprise-level performance, security, and compliance requirements. This document provides a comprehensive overview of the cloud infrastructure architecture required to deploy ElexRatio BriefCMS on **Google Cloud Platform (GCP)**.

The infrastructure spans four distinct environments: **Development (Dev)** , **Test**, **User Acceptance Testing (UAT)** , and **Production**. Each environment is configured with appropriate resource allocations to support its specific purpose while maintaining consistency in architecture and security practices.

The architecture leverages GCP managed services including **Google Kubernetes Engine (GKE)** for container orchestration, **Cloud SQL** for relational database management, and **Cloud Storage** for scalable object storage.

---

## Environment Overview

| Environment | Purpose | Description |
|-------------|---------|-------------|
| **Development** | Active Development | Used by developers for feature development, debugging, and initial integration testing |
| **Test** | QA Testing | Dedicated environment for QA team to perform functional, regression, and performance testing |
| **UAT** | User Acceptance Testing | Pre-production environment for business stakeholders to validate features before production release |
| **Production** | Live System | Production environment serving end users with full high availability and disaster recovery |

### Naming Convention

All resources follow: `{application}-{resource}-{environment}`

**Examples:**
- `briefcms-db-prod`
- `briefcms-db-uat`
- `briefcms-db-test`
- `briefcms-db-dev`

---

## Deployed Components

| Service | Purpose | Min Replicas | Max Replicas |
|---------|---------|--------------|--------------|
| **kat-api** | Core API for case management operations | 1-3 | 3-10 |
| **ktaiflow-api** | Workflow processing engine (BRE) | 1-3 | 3-15 |
| **kat-admin-studio** | Administrative dashboard interface | 1-2 | 2-5 |
| **kat-dynamic-portal** | Customer-facing portal application | 1-3 | 3-10 |
| **ktaiflow-ui** | AI workflow user interface | 1-2 | 2-8 |
| **ktai-doc-service** | Document processing service (OCR, MergePDF) | 1-2 | 2-5 |
| **redis** | Cache service for performance improvement | 1 | 2-3 |

---

## Resource Allocation by Environment

### kat-api (Core API)

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| CPU Request | 0.25 | 0.5 | 0.5 | 1 |
| CPU Limit | 0.5 | 1 | 1 | 2 |
| Memory Request | 1Gi | 2Gi | 2Gi | 4Gi |
| Memory Limit | 2Gi | 4Gi | 4Gi | 8Gi |
| Replicas (Min-Max) | 1-2 | 2-4 | 2-6 | 3-10 |

### ktaiflow-api (Workflow BRE Engine)

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| CPU Request | 1 | 2 | 2 | 4 |
| CPU Limit | 2 | 4 | 4 | 8 |
| Memory Request | 2Gi | 4Gi | 4Gi | 8Gi |
| Memory Limit | 4Gi | 8Gi | 8Gi | 16Gi |
| Replicas (Min-Max) | 1-2 | 2-4 | 2-8 | 3-15 |

### kat-admin-studio (Admin Dashboard)

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| CPU Request | 0.25 | 0.25 | 0.5 | 1 |
| CPU Limit | 0.5 | 0.5 | 1 | 2 |
| Memory Request | 512Mi | 1Gi | 1Gi | 2Gi |
| Memory Limit | 1Gi | 2Gi | 2Gi | 4Gi |
| Replicas (Min-Max) | 1 | 1-2 | 2-3 | 2-5 |

### kat-dynamic-portal (Customer Portal)

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| CPU Request | 0.25 | 0.5 | 0.5 | 1 |
| CPU Limit | 0.5 | 1 | 1 | 2 |
| Memory Request | 512Mi | 1Gi | 1Gi | 2Gi |
| Memory Limit | 1Gi | 2Gi | 2Gi | 4Gi |
| Replicas (Min-Max) | 1-2 | 2-4 | 2-6 | 3-10 |

### ktaiflow-ui (AI Workflow UI)

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| CPU Request | 0.25 | 0.25 | 0.5 | 1 |
| CPU Limit | 0.5 | 0.5 | 1 | 2 |
| Memory Request | 512Mi | 1Gi | 1Gi | 2Gi |
| Memory Limit | 1Gi | 2Gi | 2Gi | 4Gi |
| Replicas (Min-Max) | 1 | 1-2 | 2-4 | 2-8 |

### ktai-doc-service (Document Service)

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| CPU Request | 1 | 2 | 2 | 4 |
| CPU Limit | 2 | 4 | 4 | 8 |
| Memory Request | 2Gi | 4Gi | 4Gi | 8Gi |
| Memory Limit | 4Gi | 8Gi | 8Gi | 16Gi |
| Replicas (Min-Max) | 1-2 | 2-4 | 2-8 | 3-15 |

### redis (Cache Service)

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| CPU Request | 0.25 | 0.25 | 0.5 | 1 |
| CPU Limit | 0.5 | 0.5 | 1 | 2 |
| Memory Request | 512Mi | 1Gi | 1Gi | 2Gi |
| Memory Limit | 1Gi | 2Gi | 2Gi | 4Gi |
| Replicas (Min-Max) | 1 | 1-2 | 2-3 | 2-3 |

---

## GKE Cluster Configuration

### Cluster Specifications

| Configuration | Dev | Test | UAT | Production |
|---------------|-----|------|-----|------------|
| Cluster Name | elexratio-dev | elexratio-test | elexratio-uat | elexratio-prod |
| Cluster Type | Zonal | Zonal | Regional | Regional |
| Region | us-central1 | us-central1 | us-central1 | us-central1 |
| Zones | 1 zone | 1 zone | 3 zones | 3 zones |
| K8s Version | 1.29.x-1.32.x | 1.29.x-1.32.x | 1.29.x-1.32.x | 1.29.x-1.32.x |
| Workload Identity | Enabled | Enabled | Enabled | Enabled |
| Private Cluster | Yes | Yes | Yes | Yes |

### Node Pools

**Application Pool (app-pool)** – General workloads:

| Specification | Dev | Test | UAT | Production |
|---------------|-----|------|-----|------------|
| Machine Type | n2-standard-4 | n2-standard-4 | n2-standard-8 | n2-standard-8 |
| vCPU / RAM | 4 vCPU, 16GB | 4 vCPU, 16GB | 8 vCPU, 32GB | 8 vCPU, 32GB |
| Nodes (Min-Max) | 1-3 | 2-5 | 3-10 | 6-30 |

**Workflow Pool** – Workflow BRE processing workloads:

| Specification | Dev | Test | UAT | Production |
|---------------|-----|------|-----|------------|
| Machine Type | n2-highmem-4 | n2-highmem-4 | n2-highmem-8 | n2-highmem-8 |
| vCPU / RAM | 4 vCPU, 32GB | 4 vCPU, 32GB | 8 vCPU, 64GB | 8 vCPU, 64GB |
| Nodes (Min-Max) | 0-2 | 1-3 | 2-6 | 3-15 |

---

## Cloud SQL Database

| Specification | Dev | Test | UAT | Production |
|---------------|-----|------|-----|------------|
| Instance Name | briefcms-db-dev | briefcms-db-test | briefcms-db-uat | briefcms-db-prod |
| Database Engine | PostgreSQL 15 | PostgreSQL 15 | PostgreSQL 15 | PostgreSQL 15 |
| Machine Type | db-custom-2-8192 | db-custom-2-8192 | db-custom-4-16384 | db-custom-4-16384 |
| vCPU / RAM | 2 vCPU, 8GB | 2 vCPU, 8GB | 4 vCPU, 16GB | 4 vCPU, 16GB |
| Storage (SSD) | 100GB | 100GB | 250GB | 500GB |
| High Availability | No | No | Yes | Yes |
| Backup Retention | 7 days | 7 days | 14 days | 30 days |
| Point-in-Time Recovery | No | No | Yes | Yes |

**Databases:** `briefcms_{env}`, `briefcms_analytics_{env}`

---

## Cloud Storage Buckets

| Bucket Purpose | Storage Class | Dev | Test | UAT | Production |
|----------------|---------------|-----|------|-----|------------|
| Documents & Case Files | Standard | 100GB | 200GB | 500GB | 2TB |
| Archival | Nearline | 50GB | 100GB | 250GB | 1TB |
| Static Web Assets | Standard | 5GB | 5GB | 10GB | 10GB |
| Temporary Processing | Standard | 25GB | 50GB | 50GB | 100GB |
| **TOTAL** | – | **230GB** | **455GB** | **1TB** | **3.6TB** |

**Naming:** `briefcms-{purpose}-{env}` (e.g., `briefcms-documents-prod`)

---

## IAM Service Accounts

| Service Account | Roles & Permissions |
|-----------------|---------------------|
| `elexratio-app-{env}` | Cloud SQL Client, Storage Object Admin, Secret Manager Secret Accessor, Logging Writer, Monitoring Metric Writer |
| `elexratio-ci-cd-{env}` | Artifact Registry Writer, GKE Developer, Storage Object Admin |
| `elexratio-backup-{env}` | Cloud SQL Admin, Storage Admin (backup bucket only) |

---

## Secret Manager Secrets

| Secret Name | Purpose |
|-------------|---------|
| `db-connection-string-{env}` | PostgreSQL database connection string |
| `db-password-{env}` | Database user password |
| `jwt-secret-{env}` | JWT token signing key (256-bit) |
| `encryption-master-key-{env}` | Application-level encryption key (AES-256) |
| `openai-api-key-{env}` | OpenAI API access key |
| `smtp-credentials-{env}` | Email service credentials |
| `gcs-service-account-key-{env}` | Cloud Storage access key |
| `api-client-secrets-{env}` | External API client secrets |

---

## Networking Resources

| Resource | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| VPC Network | Shared | Shared | Dedicated | Dedicated |
| Subnets | 3 | 3 | 3 | 3 |
| Load Balancer | Regional HTTP | Regional HTTP | Global HTTPS | Global HTTPS |
| Cloud NAT | Yes | Yes | Yes | Yes |
| Cloud CDN | No | No | Yes | Yes |
| Cloud Armor (WAF) | No | No | Yes | Yes |
| SSL Certificate | Self-signed | Self-signed | Managed | Managed |

---

## Security & Compliance

### Security Features

| Feature | Dev | Test | UAT | Production |
|---------|-----|------|-----|------------|
| Encryption at Rest | Google-managed | Google-managed | Google-managed | CMEK |
| TLS Version | TLS 1.2+ | TLS 1.2+ | TLS 1.3 | TLS 1.3 |
| Private Cluster | Yes | Yes | Yes | Yes |
| Cloud Armor WAF | No | No | Yes | Yes |
| Network Policies | Basic | Basic | Full | Full |
| Audit Logging | Basic | Basic | Full | Full |

### Backup & Disaster Recovery

| Component | Dev | Test | UAT | Production |
|-----------|-----|------|-----|------------|
| DB Backup Frequency | Daily | Daily | Daily | Daily |
| DB Backup Retention | 7 days | 7 days | 14 days | 30 days |
| Point-in-Time Recovery | No | No | Yes | Yes |
| Storage Versioning | No | No | Yes | Yes (7-year) |
| RTO | 24 hours | 24 hours | 8 hours | 4 hours |
| RPO | 24 hours | 24 hours | 4 hours | 1 hour |

---

## Resource Summary

| Category | Dev | Test | UAT | Production |
|----------|-----|------|-----|------------|
| GKE Clusters | 1 (Zonal) | 1 (Zonal) | 1 (Regional) | 1 (Regional) |
| Node Pools | 2 | 2 | 2 | 2 |
| App Deployments | 6 | 6 | 6 | 6 |
| Cloud SQL Instances | 1 | 1 | 1 (HA) | 1 (HA) |
| Storage Buckets | 5 | 5 | 5 | 5 |
| Total Storage | 230GB | 455GB | 1TB | 3.6TB |
| Service Accounts | 3 | 3 | 3 | 3 |
| Secrets | 8 | 8 | 8 | 8 |

---

## Verification Commands

```bash
# Check GKE cluster status
gcloud container clusters list --region us-central1

# Verify pods are running
kubectl get pods -n {namespace}

# Check services
kubectl get services -n {namespace}

# Verify ingress
kubectl get ingress -n {namespace}

# Check Cloud SQL instances
gcloud sql instances list

# List storage buckets
gsutil ls


Support
GitHub: https://github.com/BriefCMS/ElexRatio-On-GCP

Email: support@elexratio.com

Document Version: 1.0 | Last Updated: February 2026
© 2026 ElexRatio. All rights reserved.


