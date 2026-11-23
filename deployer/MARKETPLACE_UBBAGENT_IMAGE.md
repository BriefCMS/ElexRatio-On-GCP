# GCP Marketplace – UBBAgent image (CVE fix)

## Required image for listing

For the **ubbagent** container image in your GCP Marketplace listing, use the official image:

```text
gcr.io/cloud-marketplace-tools/metering/ubbagent
```

Do **not** use a custom/partner-built ubbagent image (e.g. from `elexratio-briefold/briefcms/ubbagent`). The official image is maintained by Google and is required to address CVE-2025-68121 and stay compliant.

## Resubmitting container images

1. Open [Google Cloud Marketplace Partner Portal](https://console.cloud.google.com/marketplace) and sign in.
2. Open your listing: **Solution ID** `briefcms.endpoints.able-decorator-477323-u6.cloud.goog` (able-decorator-477323-u6).
3. Go to the **Container images** (or **Container Images**) section for this listing.
4. Find the **ubbagent** image.
5. Replace it with:
   - **Image:** `gcr.io/cloud-marketplace-tools/metering/ubbagent`
   - Use the **latest** tag or a specific tag from that repository.
6. Save and **resubmit the container images section** for approval.

Complete this by **2026-03-10** to avoid removal of the listing.

## Reference

- CVE: CVE-2025-68121  
- Affected (old) image: `gcr.io/cloud-marketplace/elexratio-briefold/briefcms/ubbagent@sha256:3ddabcff...`  
- Official image: `gcr.io/cloud-marketplace-tools/metering/ubbagent`
