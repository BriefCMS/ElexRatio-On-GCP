# Google Cloud Marketplace release runbook

How to publish a new version of the ElexRatio / Brief Case Management listing, or
fix a CVE notice from Google. Written for someone doing this for the first time.

Last verified with release **9.1** on 23 Nov 2026 (Docker Desktop 29.1.3 on
Windows, PowerShell).

## When you need this

- Google emails "Vulnerabilities detected for partner: able-decorator-477323-u6"
  and gives a date after which the listing will be hidden.
- The application images or the deployer manifests changed and a new version
  must go on the Marketplace.

In both cases the work is the same: push a new set of images, point the
Producer Portal at them, pass Google's checks, submit.

## Fixed facts

| Item | Value |
|---|---|
| GCP project | `able-decorator-477323-u6` |
| Listing / service name | `briefcms.endpoints.able-decorator-477323-u6.cloud.goog` |
| Image repository | `us-docker.pkg.dev/able-decorator-477323-u6/gcr.io/elexratio` |
| Producer Portal | Console → Producer Portal → Brief Case Management → **Container images** |
| Artifact Registry | Console → Artifact Registry → `gcr.io` (location `us`) → `elexratio/...` |

The same repository also answers to `gcr.io/able-decorator-477323-u6/elexratio`,
which is the path older commands and `schema.yaml` use.

A release is **seven images** that sit side by side in that repository:

| Image | Where it comes from | What to do per release |
|---|---|---|
| `deployer` | `deployer/Dockerfile` in this repo | Rebuild and push |
| `ubbagent` | `deployer/Dockerfile.ubbagent` (Google's official metering agent) | Rebuild and push |
| `kat-api` | Built outside this repo | Add the new tags |
| `ktaiflow-api` | Built outside this repo | Add the new tags |
| `kat-dynamic-portal` | Built outside this repo | Add the new tags |
| `kat-admin-studio` | Built outside this repo | Add the new tags |
| `ktaiflow-ui` | Built outside this repo | Add the new tags |

The portal only asks for the deployer. It finds the other six next to it using
the same tag, so every image must carry the release tags.

## Rules Google enforces

Each of these caused a failed check during the 9.1 release.

1. **The portal only lists minor versions.** The Display Tag dropdown shows
   `9.1`, never `9.1.0` or `9.0.1`. A fix release therefore means a new minor
   version (9.0 → 9.1).
2. **Every image needs two tags on the same digest:** the minor tag (`9.1`) and
   the full tag (`9.1.0`).
3. **Three version numbers must match the full tag:**
   - `publishedVersion` in `deployer/schema.yaml`
   - `spec.descriptor.version` in `deployer/manifest/application.yaml.template`
   - the tag on the `ubbagent` default image in `deployer/schema.yaml`
4. **Each image must be a single image manifest, not an index.** A plain
   `docker build` + `docker push` on Docker Desktop attaches a provenance
   attestation and produces an index; Google then reports "Image not found".
5. **Each image must carry the Marketplace annotation**
   `com.googleapis.cloudmarketplace.product.service.name=services/briefcms.endpoints.able-decorator-477323-u6.cloud.goog`.
6. **Adding a tag does not fix a CVE.** A tag is only a label on existing
   bytes. Google scans the digest, so a flagged image has to be rebuilt.

## Release steps

Run everything in PowerShell.

### 1. Sign in

```powershell
gcloud auth login
gcloud config set project able-decorator-477323-u6
gcloud auth configure-docker us-docker.pkg.dev
```

If Artifact Registry in the console keeps redirecting to a billing page, the
billing account has a payment problem. Nothing can be pushed until the account
owner clears it.

### 2. Choose the version and update the three places

Pick the next minor version, for example `9.2` / `9.2.0`, then edit:

- `deployer/schema.yaml`: `publishedVersion`, the `releaseNote` text, and the
  tag at the end of the `ubbagent` `default:` line
- `deployer/manifest/application.yaml.template`: `spec.descriptor.version`

### 3. Set the variables for this session

```powershell
cd C:\ElexRepo\ElexOnGCP\deployer

$REG   = "us-docker.pkg.dev/able-decorator-477323-u6/gcr.io/elexratio"
$FULL  = "9.1.0"   # same as publishedVersion in schema.yaml
$MINOR = "9.1"     # the Display Tag you will pick in the portal
$PREV  = "9.0.0"   # full tag of the previous approved release
$ANNOTATION = "com.googleapis.cloudmarketplace.product.service.name=services/briefcms.endpoints.able-decorator-477323-u6.cloud.goog"
```

### 4. Build and push the deployer

```powershell
docker buildx build --pull --platform linux/amd64 --provenance=false --sbom=false --annotation $ANNOTATION -t "$REG/deployer:$FULL" -t "$REG/deployer:$MINOR" -f Dockerfile . --push
```

What the flags are for:

| Flag | Why |
|---|---|
| `--pull` | Fetches Google's latest base image instead of a stale local copy |
| `--platform linux/amd64` | Marketplace runs on amd64 |
| `--provenance=false --sbom=false` | Keeps the result a single manifest (rule 4) |
| `--annotation ...` | Adds the Marketplace annotation (rule 5) |
| two `-t` flags | Puts both tags on one digest (rule 2) |
| `--push` | Pushes straight from the build; do not use a separate `docker push` |

The first build takes a few minutes because it compiles `kubectl` (see
"Why the deployer Dockerfile compiles kubectl" below).

### 5. Build and push ubbagent

```powershell
docker buildx build --pull --no-cache --platform linux/amd64 --provenance=false --sbom=false --annotation $ANNOTATION -t "$REG/ubbagent:$FULL" -t "$REG/ubbagent:$MINOR" -f Dockerfile.ubbagent . --push
```

`Dockerfile.ubbagent` is one line that starts from Google's official
`gcr.io/cloud-marketplace-tools/metering/ubbagent`. Rebuilding picks up Google's
fixes. Do not build ubbagent from source.

### 6. Tag the five application images

If the application images have not changed, put the new tags on the digests of
the previous release:

```powershell
foreach ($img in "kat-api","ktaiflow-api","kat-dynamic-portal","kat-admin-studio","ktaiflow-ui") {
  gcloud artifacts docker tags add "$REG/${img}:$PREV" "$REG/${img}:$FULL"
  gcloud artifacts docker tags add "$REG/${img}:$PREV" "$REG/${img}:$MINOR"
}
```

The same thing can be done in the Artifact Registry console: open the image,
open the digest's menu, **Edit tags**. That is how it was done for 9.1.

If the application team pushed new images, tag those digests instead. If Google
flags a CVE in an application image, that image must be rebuilt by its own
pipeline first (rule 6).

### 7. Check before opening the portal

```powershell
foreach ($img in "deployer","ubbagent","kat-api","ktaiflow-api","kat-dynamic-portal","kat-admin-studio","ktaiflow-ui") {
  foreach ($tag in $FULL,$MINOR) { docker buildx imagetools inspect "$REG/${img}:$tag" }
  $hit = docker buildx imagetools inspect "$REG/${img}:$FULL" --raw | Select-String "cloudmarketplace"
  "${img} annotation: $hit"
  ""
}
```

For every image, confirm:

- `MediaType` ends in `manifest.v2+json` or `image.manifest.v1+json`. If it says
  `image.index`, the image was pushed the wrong way; redo step 4 or 5.
- `Digest` is identical for the two tags.
- The annotation line is printed, not blank.

### 8. Producer Portal

1. Open **Container images** and click **Edit** next to "Proposed releases".
2. In the release, open the **Display Tag** dropdown and pick the new minor
   version. If it was already selected, pick it again so the digest refreshes.
3. Check that the deployer digest shown matches the one from step 7.
4. Click **Done**. The portal runs two checks, which take roughly 10–20 minutes:
   - Extracting app schema
   - Running a test deployment and scanning for vulnerabilities
5. If a check fails, click **View details**, find the message in the
   troubleshooting table below, fix, push again, and click **Retry**.
6. When both show "Succeeded", click **Submit**.
7. Google reviews the submission. When it is approved, the **Publish** step in
   the left menu unlocks; publish from there.

### 9. Close the loop

- Reply on the Partner Support case email: deployer rebuilt, ubbagent rebuilt
  from the official image, container images resubmitted as version X.Y.
- Commit and push the changes in this repo so the next person starts from what
  was actually released.

## Why the deployer Dockerfile compiles kubectl

Google's base image `gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst`
contains `kubectl`, the only Go program in the deployer. The Marketplace scanner
reports Go CVEs against it as package `toolchain`, type `GO_STDLIB`.

In November 2026 the base shipped kubectl v1.37.2 built with Go 1.26.10, flagged
for CVE-2026-97040 (fixed in Go 1.26.11). No kubectl release was built with the
fixed Go, so pulling a newer base could not help. `deployer/Dockerfile`
therefore compiles the same kubectl version with a patched Go and overwrites the
one in the base image.

When the scanner flags another Go CVE in the deployer:

1. Read "Fixed Version" in the scanner message.
2. See what the base image ships today:

   ```powershell
   docker pull gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst
   docker run --rm --entrypoint kubectl gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst version --client -o yaml
   ```

3. If the base's `goVersion` is already at or above the fixed version, delete
   the `kubectl-build` stage and the `RUN --mount ... install` step from
   `deployer/Dockerfile`; a plain rebuild is enough.
4. Otherwise set `GO_VERSION` in `deployer/Dockerfile` to the fixed version, and
   set `KUBECTL_VERSION` to the `gitVersion` printed in step 2.
5. Rebuild (step 4 of the release) and confirm:

   ```powershell
   docker run --rm --entrypoint kubectl "$REG/deployer:$FULL" version --client -o yaml
   ```

   `goVersion` must be the fixed version or newer.

## Troubleshooting

| Message in the portal | Cause | Fix |
|---|---|---|
| The version you want is missing from the Display Tag dropdown | Only minor versions are listed, and only after the tag exists in the registry | Push the minor tag (`9.1`); release as a new minor version |
| `Failed to extract schema from deployer ... Image not found` | Deployer was pushed as an index, or without the annotation | Rebuild with the exact command in step 4 |
| `Application resource's spec.descriptor.version "X" does not match schema.yaml's publishedVersion "Y"` | `application.yaml.template` was not updated | Make the three version numbers match (rule 3), rebuild deployer |
| `Packages below are known to contain vulnerabilities` with `Package Type: GO_STDLIB` on the deployer | kubectl in the base image is built with an old Go | See "Why the deployer Dockerfile compiles kubectl" |
| Same message for `ubbagent` | Stale ubbagent | Redo step 5; `--pull --no-cache` fetches Google's current image |
| Same message for an application image | The application image itself is vulnerable | Rebuild it in its own pipeline, then tag it (step 6) |
| "Display tag ... no longer associated with the same digests" (yellow note) | A released tag was moved to a new digest | Informational. Prefer a new minor version over re-pushing an old tag |
| Submit button is grey | Nothing changed since the last approved submission, or a check has not passed | Edit the release, or fix the failing check |

## Release history

| Version | Date | Deployer digest | Notes |
|---|---|---|---|
| 9.0 | Approved 18 Jun 2026 | `sha256:cc1a8049...` | Flagged in Nov 2026 for Go CVEs in kubectl |
| 9.1 | Checks passed 23 Nov 2026 | `sha256:478e045e9323...` | kubectl recompiled with Go 1.26.11; ubbagent rebuilt from the official image |

Add a row for each release.

## Older files in this repo

- `publish_marketplace_deployer.sh` and `publish_marketplace_deployer_buildx.sh`
  were not used for 9.1. The first builds from the repo root, which picks up the
  root `schema.yaml` (version 2.3.0) instead of `deployer/schema.yaml`. Do not
  run them without updating them first.
- `deployer/MARKETPLACE_UBBAGENT_IMAGE.md` is an earlier note about a ubbagent
  CVE. Where it differs from this runbook, follow this runbook.
- Root-level `schema.yaml`, `manifest/` and `params.env` belong to the 2.3.0
  package and are not part of the current deployer image.
