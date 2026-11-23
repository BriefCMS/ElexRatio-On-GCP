# The kubectl shipped in Google's deployer_envsubst base image is compiled with
# a Go version that the Marketplace scanner flags (CVE-2026-97040, fixed in Go
# 1.26.11). No upstream kubectl release is built with the fixed Go yet, so the
# same kubectl version is recompiled here with a patched Go and swapped in.
# When the scanner flags a newer Go CVE, bump GO_VERSION. This stage can be
# removed once the base image ships a kubectl built with a fixed Go.
ARG GO_VERSION=1.26.11
ARG KUBECTL_VERSION=v1.37.2

FROM golang:${GO_VERSION}-bookworm AS kubectl-build
ARG KUBECTL_VERSION
RUN git clone --depth 1 --branch "${KUBECTL_VERSION}" \
      https://github.com/kubernetes/kubernetes.git /src
WORKDIR /src
RUN set -eu; \
    v="${KUBECTL_VERSION}"; \
    major="$(echo "${v#v}" | cut -d. -f1)"; \
    minor="$(echo "${v#v}" | cut -d. -f2)"; \
    commit="$(git rev-parse HEAD)"; \
    built="$(date -u -d "@$(git show -s --format=%ct HEAD)" +%Y-%m-%dT%H:%M:%SZ)"; \
    ld="-s -w"; \
    for pkg in k8s.io/client-go/pkg/version k8s.io/component-base/version; do \
      ld="$ld -X $pkg.gitVersion=$v -X $pkg.gitMajor=$major -X $pkg.gitMinor=$minor"; \
      ld="$ld -X $pkg.gitCommit=$commit -X $pkg.gitTreeState=clean -X $pkg.buildDate=$built"; \
    done; \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
      go build -trimpath -ldflags "$ld" -o /out/kubectl ./cmd/kubectl

FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst

# Overwrite the base image's kubectl in place (same path, same version).
RUN --mount=type=bind,from=kubectl-build,source=/out/kubectl,target=/tmp/kubectl \
    install -m 0755 /tmp/kubectl "$(readlink -f /opt/kubectl/default)/kubectl" \
 && kubectl version --client

COPY schema.yaml /data/schema.yaml
COPY manifest /data/manifest
