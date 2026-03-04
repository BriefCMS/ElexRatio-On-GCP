# ElexRatio BriefCMS – Log Storage Requirements

## Production Baseline: 1,000,000 Case Transactions / Year (~2,740/Day)

### Google Cloud Platform (GCP) Deployment
### Multi-Environment Configuration (Dev | Test | UAT | Production)

---

## 1. Introduction

This document provides a detailed breakdown of storage requirements for application logging across all four environments of ElexRatio BriefCMS deployed on Google Cloud Platform. The estimates are derived from the infrastructure Bill of Materials (BoM) and are calibrated against a production baseline of 1,000,000 case transactions per year (approximately 2,740 case transactions per day).

Logging is implemented using **Serilog**, a structured logging framework for .NET Core applications, writing to GCP Cloud Logging with configurable sinks for long-term retention and analysis. The storage projections account for Serilog's JSON-structured output format, which includes enriched properties such as correlation IDs, request context, and service metadata.

---

## 2. Assumptions

The following assumptions underpin all storage calculations presented in this document. Any deviation from these assumptions may materially affect the estimated log volumes and storage requirements.

> **Note:** The numbers provided are indicative estimates and may vary depending on transaction volume, system integrations, logging levels, and the archival strategy implemented.

### 2.1 Transaction Volume Assumptions

| Assumption | Value / Detail |
|------------|----------------|
| Annual case transaction volume (Prod) | 1,000,000 case transactions per year |
| Daily case transactions (Prod) | ~2,740 per day (1M ÷ 365), evenly distributed |
| Transaction distribution across the year | Uniform distribution assumed; actual load may vary by court calendar, filing deadlines, and business cycles |
| Definition of a "case transaction" | A single atomic business operation such as case filing, document upload, case status update, hearing schedule, or workflow trigger |
| Log events per case transaction | ~106 log events per transaction (50 DB reads + 15 API calls + 8 DB writes + 30 app events + 3 backend jobs) |
| Environment scaling ratios | Dev: 0.5% of Prod volume (~14 txns/day), Test: 3% (~82 txns/day), UAT: 8% (~219 txns/day) |
| Background / system log events | Health checks, K8s probes, cron jobs generate ~5,000–15,000 additional entries/day in Prod independent of case transactions |

### 2.2 Logging Framework Assumptions

| Assumption | Value / Detail |
|------------|----------------|
| Logging framework | Serilog for .NET Core with JSON-structured output (CompactJsonFormatter) |
| Average log entry size (JSON) | Ranges from 0.35 KB (Application logs) to 3.5 KB (Exception logs with stack traces); weighted average ~0.7 KB per entry |
| Serilog enrichment overhead | Each log entry includes CorrelationId, ServiceName, Environment, MachineName, ThreadId, RequestPath, and Timestamp; adds ~150–200 bytes per entry |
| Log level configuration | Dev/Test: Verbose (Debug + Trace), UAT/Prod: Application (Information level); switchable at runtime via Serilog's reloadOnChange |
| Verbose level captures | 100% of all log events including debug traces, SQL query text, full request/response bodies, and cache operation details |
| Application level captures | ~35% of total events — business events, HTTP request summaries, warnings, and errors; excludes debug/trace level data |
| Minimum level captures | ~12% of total events — only Warning, Error, and Critical severity; used for cost-optimized or archival mode |
| Request/Response body logging | API request/response payloads are truncated at 1 KB (Prod/UAT) and 2 KB (Dev/Test) via Serilog Destructure settings |
| Exception stack trace depth | Average 3.5 KB per exception log entry; includes inner exceptions up to 3 levels deep |

### 2.3 Infrastructure & Retention Assumptions

| Assumption | Value / Detail |
|------------|----------------|
| Deployment platform | Google Cloud Platform (GCP) with GKE-managed Kubernetes clusters across 4 environments |
| Number of microservices generating logs | 7 services: kat-api, ktaiflow-api, kat-admin-studio, kat-dynamic-portal, ktaiflow-ui, ktai-doc-service, redis |
| Log retention — Development | 7 days (short-lived debug cycles; older logs auto-purged) |
| Log retention — Test | 14 days (covers 2-week sprint/test cycles) |
| Log retention — UAT | 30 days (covers stakeholder validation and regression windows) |
| Log retention — Production | 90 days in Cloud Logging hot storage; extended archival via GCS for compliance |
| Storage buffer | 20% buffer applied on top of calculated retention storage to account for peak spikes, incident Verbose switches, and Serilog metadata overhead |
| Compression for archival | GCS archival uses gzip compression with estimated 4:1 to 5:1 ratio for JSON logs; compression savings NOT included in primary BoM figures (applied separately in archival tier) |
| Log sink destinations | Primary: GCP Cloud Logging (hot); Secondary: GCS buckets (archival); Optional: Seq or Elasticsearch for advanced correlation |
| Replica scaling impact | Log volume estimates assume average replica counts (not max); HPA auto-scaling to max replicas can increase log volume by up to 2–3x during sustained peak |
| PII and sensitive data | API request/response logs are assumed to have PII masked via Serilog's Destructure configuration before writing to sinks; no additional storage impact from masking |
| Database audit logs | PostgreSQL native audit logs (Cloud SQL) are NOT included in these estimates; they are managed separately by Cloud SQL and billed under database storage |

### 2.4 Exclusions

The following items are explicitly excluded from this log storage BoM:

- GKE system-level logs (kubelet, kube-proxy, control plane)
- Cloud SQL PostgreSQL slow query logs and native audit logs
- GCP Audit Logs (Admin Activity and Data Access logs billed by GCP separately)
- Third-party service logs (OpenAI API call logs retained by OpenAI)
- Cloud CDN and Cloud Armor WAF access logs
- Cloud Pub/Sub delivery logs
- Infrastructure-as-Code / CI-CD pipeline logs (managed by Artifact Registry and Cloud Build)

---

## 3. Log Categories

The BriefCMS platform generates six primary categories of logs across its microservice architecture. Each category serves a distinct observability purpose and has different volume characteristics.

| Log Category | Description | Entries/Day (Prod) | Avg Size |
|--------------|-------------|-------------------|----------|
| **Read Logs** | Database read operations, cache hits/misses, file reads, search queries (~50 reads per case transaction) | 137.0K | 0.4 KB |
| **Transaction Logs** | Core business transactions, CRUD operations, workflow state changes, case updates (~8 writes per case transaction) | 21.9K | 0.8 KB |
| **Exception Logs** | Unhandled exceptions, error stack traces, failed validations, timeout errors (~0.5% error rate) | 420 | 3.5 KB |
| **Application Logs** | Service startup/shutdown, health checks, configuration changes, feature toggles (~30 app events per case transaction + background) | 95.0K | 0.35 KB |
| **API Request/Response** | HTTP request metadata, response codes, payload summaries, latency metrics (~15 API calls per case transaction) | 41.1K | 1.8 KB |
| **DAGs / Backend Jobs** | Scheduled jobs, workflow DAG executions, batch processing, AI pipeline runs, Pub/Sub processing (~3 jobs per case transaction + scheduled) | 10.2K | 1 KB |

### 3.1 Log Sources by Microservice

Each BriefCMS microservice contributes to multiple log categories. The following mapping shows the primary log generators:

| Service | Primary Log Categories | Secondary Log Categories |
|---------|------------------------|--------------------------|
| **kat-api** | Transaction Logs, API Req/Res | Read Logs, Exception Logs, Application Logs |
| **ktaiflow-api** | DAGs/Backend Jobs, Transaction Logs | Exception Logs, Application Logs, API Req/Res |
| **kat-admin-studio** | Application Logs, Read Logs | API Req/Res, Exception Logs |
| **kat-dynamic-portal** | API Req/Res, Read Logs | Transaction Logs, Exception Logs, Application Logs |
| **ktaiflow-ui** | Application Logs, API Req/Res | Exception Logs |
| **ktai-doc-service** | DAGs/Backend Jobs, Transaction Logs | Exception Logs, Application Logs |
| **redis** | Read Logs (cache ops) | Application Logs |

---

## 4. Serilog Configuration & Log Levels

BriefCMS uses Serilog as its structured logging framework across all .NET Core microservices. Serilog outputs JSON-structured log events enriched with contextual properties including CorrelationId, ServiceName, Environment, MachineName, and RequestPath.

### 4.1 Log Level Definitions

Three operational logging profiles are defined for BriefCMS, each determining the volume and granularity of captured log data:

| Log Profile | Serilog MinLevel | What Gets Captured | Typical Use | Volume Factor |
|-------------|------------------|---------------------|-------------|---------------|
| **Verbose** | Verbose / Debug | All log events including debug traces, detailed request bodies, SQL queries, cache operations | Dev environment, troubleshooting production issues | 100% (Baseline) |
| **Application** | Information | Business events, HTTP requests, job completions, warnings, and errors; excludes debug/trace data | UAT, standard Production operations | ~35% of Verbose |
| **Minimum** | Warning | Only warnings, errors, and critical failures; no informational or debug events | Cost-optimized Production, archival mode | ~12% of Verbose |

### 4.2 Recommended Log Level per Environment

| **Development** | **Test** | **UAT** | **Production** |
|-----------------|----------|---------|----------------|
| **Verbose** | **Verbose** | **Application** | **Application** |

> **Note:** Production can be temporarily switched to Verbose during incident investigation and reverted after resolution.

### 4.3 Serilog Sink Configuration

Each environment writes logs to multiple sinks for different retention and analysis needs:

| Sink | Purpose | Format | Retention Managed By |
|------|---------|--------|---------------------|
| **GCP Cloud Logging** | Real-time monitoring, alerting, dashboards | JSON (Serilog.Sinks.GoogleCloudLogging) | Cloud Logging retention policy |
| **Cloud Storage (GCS)** | Long-term archival, compliance audit trail | NDJSON compressed (gzip) | Bucket lifecycle rules |
| **Console (stdout)** | Kubernetes pod log collection, kubectl access | JSON compact | GKE log rotation |
| **Seq / Elastic (Optional)** | Advanced search, correlation analysis | JSON structured | Index lifecycle management |

---

## 5. Environment-wise Log Volume Estimation

The following sections provide detailed daily log volume estimates per environment. Production is the baseline at 1,000,000 case transactions/year (~2,740/day). Each case transaction generates multiple underlying log events across services (API calls, DB reads/writes, workflow jobs, etc.). Lower environments are scaled proportionally: Dev at 0.5%, Test at 3%, UAT at 8% of production transaction volume.

### 5.1 Environment Scale Factors

| Environment | Case Transactions | Scale Factor | Retention Period |
|-------------|-------------------|--------------|------------------|
| **Development** | ~14/day (2,500/yr) | 0.5% | 7 days |
| **Test** | ~82/day (15,000/yr) | 3% | 14 days |
| **UAT** | ~219/day (40,000/yr) | 8% | 30 days |
| **Production** | ~2,740/day (1M/yr) | 100% | 90 days |

### 5.2 Development Environment

Verbose logging recommended. Low transaction volume supports full debug-level capture for development troubleshooting.

| Log Category | Verbose (Daily) | Application (Daily) | Minimum (Daily) | Recommended |
|--------------|-----------------|---------------------|-----------------|-------------|
| **Read Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Transaction Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Exception Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Application Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **API Request/Response** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **DAGs / Backend Jobs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **TOTAL (Daily)** | **< 1 MB** | **< 1 MB** | **< 1 MB** | **< 1 MB** |
| **TOTAL (7-day retention)** | **7 MB** | **2 MB** | **< 1 MB** | **7 MB** |

### 5.3 Test Environment

Verbose logging for QA validation. Moderate volume allows comprehensive log analysis during test cycles.

| Log Category | Verbose (Daily) | Application (Daily) | Minimum (Daily) | Recommended |
|--------------|-----------------|---------------------|-----------------|-------------|
| **Read Logs** | 2 MB | < 1 MB | < 1 MB | **2 MB** |
| **Transaction Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Exception Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Application Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **API Request/Response** | 2 MB | < 1 MB | < 1 MB | **2 MB** |
| **DAGs / Backend Jobs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **TOTAL (Daily)** | **6 MB** | **2 MB** | **< 1 MB** | **6 MB** |
| **TOTAL (14-day retention)** | **78 MB** | **27 MB** | **9 MB** | **78 MB** |

### 5.4 UAT Environment

Application-level logging recommended. Pre-production validation with business stakeholder access to meaningful logs.

| Log Category | Verbose (Daily) | Application (Daily) | Minimum (Daily) | Recommended |
|--------------|-----------------|---------------------|-----------------|-------------|
| **Read Logs** | 4 MB | 1 MB | < 1 MB | **1 MB** |
| **Transaction Logs** | 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Exception Logs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Application Logs** | 3 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **API Request/Response** | 6 MB | 2 MB | < 1 MB | **2 MB** |
| **DAGs / Backend Jobs** | < 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **TOTAL (Daily)** | **15 MB** | **5 MB** | **2 MB** | **5 MB** |
| **TOTAL (30-day retention)** | **448 MB** | **157 MB** | **54 MB** | **157 MB** |

### 5.5 Production Environment

Application-level logging as default. Can temporarily switch to Verbose for incident investigation. Minimum level available for cost optimization during stable periods.

| Log Category | Verbose (Daily) | Application (Daily) | Minimum (Daily) | Recommended |
|--------------|-----------------|---------------------|-----------------|-------------|
| **Read Logs** | 54 MB | 19 MB | 6 MB | **19 MB** |
| **Transaction Logs** | 17 MB | 6 MB | 2 MB | **6 MB** |
| **Exception Logs** | 1 MB | < 1 MB | < 1 MB | **< 1 MB** |
| **Application Logs** | 32 MB | 11 MB | 4 MB | **11 MB** |
| **API Request/Response** | 72 MB | 25 MB | 9 MB | **25 MB** |
| **DAGs / Backend Jobs** | 10 MB | 3 MB | 1 MB | **3 MB** |
| **TOTAL (Daily)** | **187 MB** | **65 MB** | **22 MB** | **65 MB** |
| **TOTAL (90-day retention)** | **16.4 GB** | **5.7 GB** | **2.0 GB** | **5.7 GB** |

---

## 6. Consolidated Storage Summary (BoM)

The following table consolidates the total log storage required across all environments using the recommended log level per environment, including retention-based storage requirements.

| Environment | Log Level | Daily Volume | Retention | Total Storage | With 20% Buffer |
|-------------|-----------|--------------|-----------|---------------|-----------------|
| **Development** | Verbose | < 1 MB | 7 days | **7 MB** | **8 MB** |
| **Test** | Verbose | 6 MB | 14 days | **78 MB** | **94 MB** |
| **UAT** | Application | 5 MB | 30 days | **157 MB** | **188 MB** |
| **Production** | Application | 65 MB | 90 days | **5.7 GB** | **6.9 GB** |
| **GRAND TOTAL** | --- | --- | --- | **6.0 GB** | **7.2 GB** |

> **Note:** The 20% buffer accounts for log volume spikes during peak transaction periods, incident investigations requiring temporary Verbose logging, and overhead from Serilog's JSON enrichment properties.

### 6.1 What-If: All-Verbose vs All-Minimum Scenario

| Environment | All Verbose (Total) | Recommended (Total) | All Minimum (Total) |
|-------------|---------------------|---------------------|---------------------|
| **Development** | 7 MB | **7 MB** | < 1 MB |
| **Test** | 78 MB | **78 MB** | 9 MB |
| **UAT** | 448 MB | **157 MB** | 54 MB |
| **Production** | 16.4 GB | **5.7 GB** | 2.0 GB |
| **GRAND TOTAL** | **16.9 GB** | **6.0 GB** | **2.0 GB** |

---

## 7. Peak Time Load Analysis

While the baseline estimates assume uniform daily transaction distribution, real-world legal case management systems experience significant traffic peaks tied to court filing deadlines, business hours, end-of-quarter surges, and batch processing windows. This section models the impact of peak load periods on log storage requirements.

### 7.1 Peak Load Scenarios

BriefCMS is expected to encounter three distinct peak load patterns based on legal industry workflows:

| Peak Scenario | Multiplier | Duration | Trigger | Affected Services |
|---------------|------------|----------|---------|-------------------|
| **Business Hours Peak** | **3x** | 8 hrs/day | Concentrated user activity during 9 AM–5 PM business hours; 70–80% of daily transactions occur within this window | All services |
| **Filing Deadline Surge** | **5x** | 2–4 hrs | Court filing deadlines, regulatory submission cutoffs, end-of-month/quarter batch filings | kat-api, ktaiflow-api, ktai-doc-service |
| **Batch Processing Window** | **4x** | 1–3 hrs | Nightly/scheduled AI document processing, OCR batch jobs, workflow DAG bulk executions, report generation | ktaiflow-api, ktai-doc-service, DAGs/Jobs |
| **Incident + Verbose Mode** | **8–10x** | 1–4 hrs | Production incident triggers temporary Verbose logging on affected services for root cause analysis | Targeted services (typically 1–2) |

### 7.2 Peak Hour Log Volume by Environment

The following table shows the estimated peak-hour log generation rate for each environment under a 3x business hours peak scenario (recommended log level applied). Peak hour volume is calculated as: (Daily Volume ÷ 24 hours) × 3x multiplier.

| Log Category | Dev (Peak/hr) | Test (Peak/hr) | UAT (Peak/hr) | Prod (Peak/hr) |
|--------------|---------------|----------------|---------------|----------------|
| **Read Logs** | < 1 MB | < 1 MB | < 1 MB | 2 MB |
| **Transaction Logs** | < 1 MB | < 1 MB | < 1 MB | < 1 MB |
| **Exception Logs** | < 1 MB | < 1 MB | < 1 MB | < 1 MB |
| **Application Logs** | < 1 MB | < 1 MB | < 1 MB | 1 MB |
| **API Request/Response** | < 1 MB | < 1 MB | < 1 MB | 3 MB |
| **DAGs / Backend Jobs** | < 1 MB | < 1 MB | < 1 MB | < 1 MB |
| **TOTAL (Peak Hour)** | **< 1 MB** | **< 1 MB** | **< 1 MB** | **8 MB** |

### 7.3 Peak Day Storage Impact (Filing Deadline Surge)

During a filing deadline surge day, transaction volumes spike to 5x the normal rate for a 2–4 hour window. Combined with normal business hours activity, a peak day generates approximately 2x the average daily log volume. The following table models the storage impact of peak days occurring at different frequencies across the retention period.

| Environment | Baseline Total (Retention) | With 10% Peak Days | With 20% Peak Days |
|-------------|----------------------------|---------------------|---------------------|
| **Development** | 7 MB | **7 MB** | **8 MB** |
| **Test** | 78 MB | **86 MB** | **94 MB** |
| **UAT** | 157 MB | **173 MB** | **188 MB** |
| **Production** | 5.7 GB | **6.3 GB** | **6.9 GB** |
| **GRAND TOTAL** | **6.0 GB** | **6.6 GB** | **7.2 GB** |

### 7.4 Worst-Case Peak Storage (Production)

The following models the worst-case production storage scenario where multiple peak conditions overlap: filing deadline surges, temporary Verbose logging during incident investigation, and HPA auto-scaling to maximum replicas.

| Scenario | Daily Volume (Prod) | 90-Day Retention |
|----------|---------------------|------------------|
| **Normal Day (Application level)** | 65 MB | 5.7 GB |
| **Peak Day — 3x Business Hours** | 131 MB | 11.5 GB |
| **Peak Day — 5x Filing Deadline Surge** | 163 MB | 14.4 GB |
| **Incident Day — Verbose on 2 services (4 hrs)** | 71 MB | 6.3 GB |
| **Worst Case — Surge + Verbose + Max HPA** | **229 MB** | **20.1 GB** |

> **Recommendation:** Provision production log storage based on the "20% Peak Days" model with a 20% buffer. This covers realistic filing deadline patterns while the worst-case scenario serves as an upper bound for capacity planning alerts. Cloud Logging's pay-per-ingestion model naturally accommodates short-duration spikes without pre-provisioning.

### 7.5 Peak Load Impact on HPA and Log Volume

During peak periods, the Horizontal Pod Autoscaler (HPA) scales services to higher replica counts. More replicas generate proportionally more logs, especially Application logs (health checks, startup events) and Read logs (cache warming). The following shows the HPA scaling impact on log volume at peak:

| Service | Normal Replicas | Peak Replicas | Log Volume Multiplier | Primary Log Impact |
|---------|-----------------|---------------|----------------------|--------------------|
| **kat-api** | 3–5 | 8–10 | **2–3x** | API Req/Res, Read Logs |
| **ktaiflow-api** | 3–6 | 10–15 | **2.5–4x** | DAGs/Jobs, Transaction Logs |
| **kat-admin-studio** | 2–3 | 4–5 | **1.5–2x** | Application Logs |
| **kat-dynamic-portal** | 3–5 | 8–10 | **2–3x** | API Req/Res, Read Logs |
| **ktaiflow-ui** | 2–4 | 6–8 | **1.5–2x** | Application Logs |
| **ktai-doc-service** | 2–3 | 4–5 | **1.5–2x** | DAGs/Jobs, Exception Logs |

> **Note:** The HPA log volume multiplier accounts for both increased transaction throughput and additional per-replica system events (startup, health checks, metrics emission). The actual multiplier depends on the scaling speed and stabilization window configured in the HPA behavior profiles.

---

## Support

- **GitHub**: [https://github.com/BriefCMS/ElexRatio-On-GCP](https://github.com/BriefCMS/ElexRatio-On-GCP)
- **Email**: [support@elexratio.com](mailto:support@elexratio.com)

---

*Document Version: 1.1 | Last Updated: March 2026*
*© 2026 ElexRatio. All rights reserved.*