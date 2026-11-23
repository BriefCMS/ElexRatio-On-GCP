# ElexRatio on Google Cloud Marketplace

ElexRatio is a multi-service dags orchestration, compliance, and workflow management platform designed to run on **Google Kubernetes Engine (GKE)**.

This repository holds the Google Cloud Marketplace package for ElexRatio (listed as **Brief Case Management**): the deployer image source, the Kubernetes manifests, and the documentation.

## Components

* kat-api
* ktaiflow-api
* kat-admin-studio
* kat-dynamic-portal
* ktaiflow-ui

## Deployment

ElexRatio can be deployed using **Google Cloud Marketplace** or directly via **kubectl**.

Full installation and usage instructions: [`docs/user-guide.md`](docs/user-guide.md)

## Repository layout

| Path | Purpose |
|---|---|
| `deployer/` | Source of the Marketplace deployer image. This is what gets released. |
| `deployer/Dockerfile` | Builds the deployer on Google's `deployer_envsubst` base |
| `deployer/Dockerfile.ubbagent` | Builds the usage-metering agent from Google's official image |
| `deployer/schema.yaml` | Marketplace schema: version, image list, install parameters |
| `deployer/manifest/` | Kubernetes templates the deployer applies |
| `deploy/` | Manifests and parameters for a manual `kubectl` install |
| `docs/` | User guide, release runbook, log storage requirements |
| `Deployment/` | Infrastructure architecture document |
| `test/` | Install test script |
| `schema.yaml`, `manifest/`, `params.env` (root) | Earlier 2.3.0 package; not part of the current deployer image |

## Releasing a new Marketplace version

For maintainers. The full procedure, the rules Google enforces, and a troubleshooting table are in [`docs/marketplace-release-runbook.md`](docs/marketplace-release-runbook.md). Read it before your first release.

In short:

1. Set the new version in `deployer/schema.yaml` (`publishedVersion` and the `ubbagent` default tag) and in `deployer/manifest/application.yaml.template` (`spec.descriptor.version`). All three must match.
2. Build and push `deployer` and `ubbagent` with the commands below.
3. Add the same two tags to the five application images.
4. In the Producer Portal, open **Container images**, select the new Display Tag, wait for both checks to succeed, and submit.

Commands (PowerShell, run from the `deployer` folder; example for version 9.1):

```powershell
$REG   = "us-docker.pkg.dev/able-decorator-477323-u6/gcr.io/elexratio"
$FULL  = "9.1.0"
$MINOR = "9.1"
$ANNOTATION = "com.googleapis.cloudmarketplace.product.service.name=services/briefcms.endpoints.able-decorator-477323-u6.cloud.goog"

gcloud config set project able-decorator-477323-u6
gcloud auth configure-docker us-docker.pkg.dev

# Deployer
docker buildx build --pull --platform linux/amd64 --provenance=false --sbom=false --annotation $ANNOTATION -t "$REG/deployer:$FULL" -t "$REG/deployer:$MINOR" -f Dockerfile . --push

# Usage-metering agent
docker buildx build --pull --no-cache --platform linux/amd64 --provenance=false --sbom=false --annotation $ANNOTATION -t "$REG/ubbagent:$FULL" -t "$REG/ubbagent:$MINOR" -f Dockerfile.ubbagent . --push
```

Do not replace these with a plain `docker build` and `docker push`. Without `--provenance=false` and `--annotation`, Google's check fails with "Image not found".

## Documentation

* User guide: [`docs/user-guide.md`](docs/user-guide.md)
* Marketplace release runbook: [`docs/marketplace-release-runbook.md`](docs/marketplace-release-runbook.md)
* Log storage requirements: [`docs/ElexRatio_BriefCMS_Log_Storage_Requirements.md`](docs/ElexRatio_BriefCMS_Log_Storage_Requirements.md)
* License: `LICENSE`

## Support

* GitHub: [https://github.com/BriefCMS/ElexRatio-On-GCP](https://github.com/BriefCMS/ElexRatio-On-GCP)
* Email: [support@elexratio.com](mailto:support@elexratio.com)
