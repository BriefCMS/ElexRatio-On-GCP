# ElexRatio – User Guide

## Overview

**ElexRatio** is a multi-service dags, compliance, and workflow management platform designed to run on **Google Kubernetes Engine (GKE)**.
This Marketplace package deploys all required backend APIs and frontend UIs into a single Kubernetes namespace.

### Deployed Components

The Marketplace deployment installs the following services:

| Component          | Description                    |
| ------------------ | ------------------------------ |
| kat-api            | Core backend API               |
| ktaiflow-api       | Workflow and orchestration API |
| kat-admin-studio   | Admin UI                       |
| kat-dynamic-portal | Dynamic portal UI              |
| ktaiflow-ui        | Workflow UI                    |

All components are deployed and managed together as a single **Application** resource.

---

## Prerequisites

Before deploying ElexRatio, ensure that you have:

* A **Google Cloud project**
* A **GKE cluster** (Standard or Autopilot)
* `kubectl` configured to access the cluster
* A **domain name** (for Ingress access)
* Permissions to create:

  * Deployments
  * Services
  * Ingress resources
  * ManagedCertificates

---

## Deploying from Google Cloud Marketplace (UI)

1. Open **Google Cloud Console**
2. Navigate to **Marketplace**
3. Search for **ElexRatio**
4. Click **Deploy**
5. Fill in the required parameters:

   * **Namespace**: Kubernetes namespace where ElexRatio will be installed
     (default: `elexratio`)
   * **Base Domain**: Domain used to expose the services
     (example: `example.com`)
6. Click **Deploy**

The Marketplace deployer container installs all services and validates the deployment.

---

## Deploying from Command Line (kubectl)

You can also deploy ElexRatio manually using `kubectl`.

### 1. Clone the repository

```bash
git clone https://github.com/BriefCMS/ElexRatio-On-GCP.git
cd ElexRatio-On-GCP
```

### 2. Configure parameters

Edit the parameter file:

```bash
vi deploy/params.env
```

Update at least:

```env
NAMESPACE=elexratio
DOMAIN=example.com
```

### 3. Deploy the application

```bash
source deploy/params.env
./deployer/deploy.sh
```

---

## Accessing the Application

After deployment completes, the services are accessible via HTTPS using the configured domain.

| Service        | URL                                           |
| -------------- | --------------------------------------------- |
| Admin Studio   | [https://admin](https://admin).<DOMAIN>       |
| Dynamic Portal | [https://dynamicportal](https://dynamicportal).<DOMAIN>     |
| Workflow UI    | [https://aiflowui(https://aiflowui).<DOMAIN>         |
| Core API       | [https://api](https://api).<DOMAIN>           |
| Workflow API   | [https://aiflow-api](https://aiflow-api).<DOMAIN> |

> **Note:** DNS records must point your domain to the Ingress IP created by GKE.

---

## Verifying the Deployment

Run the following commands to verify installation:

```bash
kubectl get pods -n elexratio
kubectl get services -n elexratio
kubectl get ingress -n elexratio
```

All pods should be in **Running** state.

---

## Configuration Notes

* Each service runs in the same Kubernetes namespace
* Container images are configurable via parameters
* HTTPS is enabled using **Google Managed Certificates**
* The deployment supports multiple environments by adjusting `params.env`

---

## Uninstalling ElexRatio

To remove ElexRatio completely:

```bash
kubectl delete application elexratio -n elexratio
```

If required, delete the namespace:

```bash
kubectl delete namespace elexratio
```

---

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n elexratio
kubectl logs <pod-name> -n elexratio
```

### Ingress not ready

* Verify DNS is correctly mapped
* Check certificate status:

```bash
kubectl describe managedcertificate -n elexratio
```

---

## Support

For issues, documentation, or updates:

* GitHub: [https://github.com/BriefCMS/ElexRatio-On-GCP](https://github.com/BriefCMS/ElexRatio-On-GCP)
* Email: [support@elexratio.com](support@elexratio.com)

---

## License

This project is licensed under the terms described in the `LICENSE` file included in the repository.
