ElexRatio BriefCMS – Infrastructure Architecture
Overview
ElexRatio BriefCMS is a production-grade legal case management system with AI-powered document processing capabilities designed to meet enterprise-level performance, security, and compliance requirements. This document provides a comprehensive overview of the cloud infrastructure architecture required to deploy ElexRatio BriefCMS on Google Cloud Platform (GCP).

The infrastructure spans four distinct environments: Development (Dev), Test, User Acceptance Testing (UAT), and Production. Each environment is configured with appropriate resource allocations to support its specific purpose while maintaining consistency in architecture and security practices.

The architecture leverages GCP managed services including Google Kubernetes Engine (GKE) for container orchestration, Cloud SQL for relational database management, and Cloud Storage for scalable object storage. This design ensures high availability, automatic scaling, robust security, and operational efficiency across all environments.

Architecture Principles
Principle	Description
High Availability	Regional GKE cluster with multi-zone distribution ensures service continuity and fault tolerance (Production and UAT environments)
Scalability	Horizontal Pod Autoscalers dynamically adjust workloads based on CPU and memory utilization
Security	Private cluster configuration, network policies, and encryption at rest and in transit protect sensitive legal data
Environment Isolation	Each environment operates in its own GCP project or namespace with strict network boundaries
Compliance	Infrastructure designed to support SOC 2 Type II and GDPR requirements with comprehensive audit logging
Environment Overview
Environment	Purpose	Description
Development	Active Development	Used by developers for feature development, debugging, and initial integration testing
Test	QA Testing	Dedicated environment for QA team to perform functional, regression, and performance testing
UAT	User Acceptance Testing	Pre-production environment for business stakeholders to validate features before production release
Production	Live System	Production environment serving end users with full high availability and disaster recovery
Environment Naming Convention
All resources follow a consistent naming convention: {application}-{resource}-{environment}.

Examples:

briefcms-db-prod

briefcms-db-uat

briefcms-db-test

briefcms-db-dev

Deployed Components
The ElexRatio BriefCMS deployment consists of the following microservices:

Service	Purpose	Min Replicas	Max Replicas
kat-api	Core API for case management operations	1-3	3-10
ktaiflow-api	Workflow processing engine (BRE)	1-3	3-15
kat-admin-studio	Administrative dashboard interface	1-2	2-5
kat-dynamic-portal	Customer-facing portal application	1-3	3-10
ktaiflow-ui	AI workflow user interface	1-2	2-8
ktai-doc-service	Document processing service (OCR, MergePDF)	1-2	2-5
redis	Cache service for performance improvement	1	2-3
All components are deployed and managed within their respective environments with environment-specific resource allocations.

Resource Allocation by Environment
kat-api (Core API)
Resource	Dev	Test	UAT	Production
CPU Request	0.25	0.5	0.5	1
CPU Limit	0.5	1	1	2
Memory Request	1Gi	2Gi	2Gi	4Gi
Memory Limit	2Gi	4Gi	4Gi	8Gi
Replicas (Min-Max)	1-2	2-4	2-6	3-10
ktaiflow-api (Workflow BRE Engine)
Resource	Dev	Test	UAT	Production
CPU Request	1	2	2	4
CPU Limit	2	4	4	8
Memory Request	2Gi	4Gi	4Gi	8Gi
Memory Limit	4Gi	8Gi	8Gi	16Gi
Replicas (Min-Max)	1-2	2-4	2-8	3-15
kat-admin-studio (Admin Dashboard)
Resource	Dev	Test	UAT	Production
CPU Request	0.25	0.25	0.5	1
CPU Limit	0.5	0.5	1	2
Memory Request	512Mi	1Gi	1Gi	2Gi
Memory Limit	1Gi	2Gi	2Gi	4Gi
Replicas (Min-Max)	1	1-2	2-3	2-5
kat-dynamic-portal (Customer Portal)
Resource	Dev	Test	UAT	Production
CPU Request	0.25	0.5	0.5	1
CPU Limit	0.5	1	1	2
Memory Request	512Mi	1Gi	1Gi	2Gi
Memory Limit	1Gi	2Gi	2Gi	4Gi
Replicas (Min-Max)	1-2	2-4	2-6	3-10
ktaiflow-ui (AI Workflow UI)
Resource	Dev	Test	UAT	Production
CPU Request	0.25	0.25	0.5	1
CPU Limit	0.5	0.5	1	2
Memory Request	512Mi	1Gi	1Gi	2Gi
Memory Limit	1Gi	2Gi	2Gi	4Gi
Replicas (Min-Max)	1	1-2	2-4	2-8
ktai-doc-service (Document Service)
Resource	Dev	Test	UAT	Production
CPU Request	1	2	2	4
CPU Limit	2	4	4	8
Memory Request	2Gi	4Gi	4Gi	8Gi
Memory Limit	4Gi	8Gi	8Gi	16Gi
Replicas (Min-Max)	1-2	2-4	2-8	3-15
redis (Cache Service)
Resource	Dev	Test	UAT	Production
CPU Request	0.25	0.25	0.5	1
CPU Limit	0.5	0.5	1	2
Memory Request	512Mi	1Gi	1Gi	2Gi
Memory Limit	1Gi	2Gi	2Gi	4Gi
Replicas (Min-Max)	1	1-2	2-3	2-3
GKE Cluster Configuration
Cluster Specifications by Environment
Configuration	Dev	Test	UAT	Production
Cluster Name	elexratio-dev	elexratio-test	elexratio-uat	elexratio-prod
Cluster Type	Zonal	Zonal	Regional	Regional
Region	us-central1	us-central1	us-central1	us-central1
Zones	1 zone	1 zone	3 zones	3 zones
K8s Version	1.29.x-1.32.x	1.29.x-1.32.x	1.29.x-1.32.x	1.29.x-1.32.x
Workload Identity	Enabled	Enabled	Enabled	Enabled
Private Cluster	Yes	Yes	Yes	Yes
Node Pools
Application Pool (app-pool) – General workloads:

Specification	Dev	Test	UAT	Production
Machine Type	n2-standard-4	n2-standard-4	n2-standard-8	n2-standard-8
vCPU / RAM	4 vCPU, 16GB	4 vCPU, 16GB	8 vCPU, 32GB	8 vCPU, 32GB
Nodes (Min-Max)	1-3	2-5	3-10	6-30
Workflow Pool – Workflow BRE processing workloads:

Specification	Dev	Test	UAT	Production
Machine Type	n2-highmem-4	n2-highmem-4	n2-highmem-8	n2-highmem-8
vCPU / RAM	4 vCPU, 32GB	4 vCPU, 32GB	8 vCPU, 64GB	8 vCPU, 64GB
Nodes (Min-Max)	0-2	1-3	2-6	3-15
Production Auto-Scaling Configuration
Cluster Autoscaler (Node-Level)
Configuration	Value
Cluster Autoscaler	Enabled
Scale-Up Trigger	Pods pending due to insufficient resources
Scale-Down Trigger	Node utilization below 50% for 10 minutes
Scale-Down Delay	10 minutes after scale-up
App Pool Range	Minimum: 6 nodes | Maximum: 30 nodes
AI Pool Range	Minimum: 3 nodes | Maximum: 15 nodes
Horizontal Pod Autoscaler (Pod-Level Scaling)
Service	Min Pods	Max Pods	CPU Target	Memory Target	Scale Behavior
kat-api	3	10	70%	80%	Aggressive
ktaiflow-api	3	15	60%	70%	Aggressive
kat-admin-studio	2	5	75%	80%	Standard
kat-dynamic-portal	3	10	70%	80%	Aggressive
ktaiflow-ui	2	8	75%	80%	Standard
ktai-doc-service	2	5	60%	70%	Aggressive
HPA Scaling Behavior
Behavior Parameter	Aggressive Profile	Standard Profile
Scale-Up Stabilization Window	0 seconds	60 seconds
Scale-Up Max Pods (per 15s)	4 pods or 100%	2 pods or 50%
Scale-Down Stabilization Window	300 seconds	300 seconds
Scale-Down Max Pods (per 60s)	2 pods or 25%	1 pod or 20%
Pod Disruption Budgets (High Availability)
Service	Min Available	Max Unavailable
kat-api	2	1
ktaiflow-api	2	1
kat-admin-studio	1	1
kat-dynamic-portal	2	1
ktaiflow-ui	1	1
ktai-doc-service	2	1
Supporting Kubernetes Resources
Resource Type	Quantity	Purpose
Services	6	ClusterIP services for internal pod-to-pod communication
ConfigMaps	2	Environment-specific application configuration and settings
Secrets	4	Database credentials, storage keys, and API keys per environment
PersistentVolumeClaims	2	Cache storage and temporary processing storage
HorizontalPodAutoscalers	6	Automatic scaling based on CPU and memory utilization
NetworkPolicies	3	Network security rules and traffic control between pods
ServiceAccounts	2	Application and deployer service accounts for RBAC
Ingress	1	External access point with SSL/TLS termination
Cloud SQL Database
Each environment has its own Cloud SQL PostgreSQL instance with appropriate sizing.

Specification	Dev	Test	UAT	Production
Instance Name	briefcms-db-dev	briefcms-db-test	briefcms-db-uat	briefcms-db-prod
Database Engine	PostgreSQL 15	PostgreSQL 15	PostgreSQL 15	PostgreSQL 15
Machine Type	db-custom-2-8192	db-custom-2-8192	db-custom-4-16384	db-custom-4-16384
vCPU / RAM	2 vCPU, 8GB	2 vCPU, 8GB	4 vCPU, 16GB	4 vCPU, 16GB
Storage (SSD)	100GB	100GB	250GB	500GB
High Availability	No	No	Yes	Yes
Backup Retention	7 days	7 days	14 days	30 days
Point-in-Time Recovery	No	No	Yes	Yes
Network Access	Private IP	Private IP	Private IP	Private IP
Databases per instance: briefcms_{env}, briefcms_analytics_{env}

Cloud Storage Buckets
Each environment requires five Cloud Storage buckets with environment-specific naming and capacity.

Bucket Purpose	Storage Class	Dev	Test	UAT	Production
Documents & Case Files	Standard	100GB	200GB	500GB	2TB
Archival	Nearline	50GB	100GB	250GB	1TB
Static Web Assets	Standard	5GB	5GB	10GB	10GB
Temporary Processing	Standard	25GB	50GB	50GB	100GB
TOTAL	–	230GB	455GB	1TB	3.6TB
Bucket naming convention: briefcms-{purpose}-{env}

Examples:

briefcms-documents-prod

briefcms-documents-dev

IAM Service Accounts
Service Account	Roles & Permissions
elexratio-app-{env}	Cloud SQL Client, Storage Object Admin, Secret Manager Secret Accessor, Logging Writer, Monitoring Metric Writer
elexratio-ci-cd-{env}	Artifact Registry Writer, GKE Developer, Storage Object Admin
elexratio-backup-{env}	Cloud SQL Admin, Storage Admin (backup bucket only)
Secret Manager Secrets
Secret Name Pattern	Purpose
db-connection-string-{env}	PostgreSQL database connection string
db-password-{env}	Database user password
jwt-secret-{env}	JWT token signing key (256-bit)
encryption-master-key-{env}	Application-level encryption key (AES-256)
openai-api-key-{env}	OpenAI API access key (if AI features enabled)
smtp-credentials-{env}	Email service credentials for notifications
gcs-service-account-key-{env}	Cloud Storage access key (JSON format)
api-client-secrets-{env}	External API client secrets for integrations
Networking Resources
Resource	Dev	Test	UAT	Production
VPC Network	Shared	Shared	Dedicated	Dedicated
Subnets	3	3	3	3
Load Balancer	Regional HTTP	Regional HTTP	Global HTTPS	Global HTTPS
Cloud NAT	Yes	Yes	Yes	Yes
Cloud CDN	No	No	Yes	Yes
Cloud Armor (WAF)	No	No	Yes	Yes
SSL Certificate	Self-signed	Self-signed	Managed	Managed
Additional GCP Services
Service	Usage (Per Environment)
Cloud Pub/Sub	3 topics per environment: Events, AI Jobs, Alerts
Cloud Monitoring	Environment-specific dashboards and alerting policies
Cloud Logging	Centralized logging with environment-specific log sinks
Artifact Registry	Shared container image repository with environment tags
Cloud DNS	Environment-specific DNS records (e.g., dev.briefcms.com, prod.briefcms.com)
Security & Compliance
Security Features by Environment
Security Feature	Dev	Test	UAT	Production
Encryption at Rest	Google-managed	Google-managed	Google-managed	CMEK
TLS Version	TLS 1.2+	TLS 1.2+	TLS 1.3	TLS 1.3
Private Cluster	Yes	Yes	Yes	Yes
Cloud Armor WAF	No	No	Yes	Yes
Network Policies	Basic	Basic	Full	Full
Audit Logging	Basic	Basic	Full	Full
VPC Service Controls	No	No	No	Yes
Compliance
The infrastructure is designed to support the following compliance frameworks:

SOC 2 Type II: Infrastructure controls designed for SOC 2 compliance with comprehensive audit logging (Production environment)

GDPR: Data residency controls and right-to-erasure capabilities for EU compliance across all environments

Audit Logging: Comprehensive audit logging enabled for all administrative actions and data access in UAT and Production

Backup & Disaster Recovery
Component	Dev	Test	UAT	Production
DB Backup Frequency	Daily	Daily	Daily	Daily
DB Backup Retention	7 days	7 days	14 days	30 days
Point-in-Time Recovery	No	No	Yes	Yes
Storage Versioning	No	No	Yes	Yes (7-year)
RTO	24 hours	24 hours	8 hours	4 hours
RPO	24 hours	24 hours	4 hours	1 hour
Resource Summary
Resource Category	Dev	Test	UAT	Production
GKE Clusters	1 (Zonal)	1 (Zonal)	1 (Regional)	1 (Regional)
Node Pools	2	2	2	2
App Deployments	6	6	6	6
Cloud SQL Instances	1	1	1 (HA)	1 (HA)
Storage Buckets	5	5	5	5
Total Storage	230GB	455GB	1TB	3.6TB
Service Accounts	3	3	3	3
Secrets	8	8	8	8
Pub/Sub Topics	3	3	3	3
Verifying the Deployment
Run the following commands to verify the infrastructure in each environment:

bash
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
For issues, documentation, or updates:

GitHub: https://github.com/BriefCMS/ElexRatio-On-GCP

Email: support@elexratio.com

License
This project is licensed under the terms described in the LICENSE file included in the repository.

Document Version: 1.0 | Last Updated: February 2026

© 2026 ElexRatio. All rights reserved.