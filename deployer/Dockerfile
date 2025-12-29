# ---------- Stage 1: build envsubst ----------
FROM debian:bookworm-slim AS builder
RUN apt-get update && apt-get install -y gettext-base

# ---------- Stage 2: final deployer image ----------
FROM debian:bookworm-slim
USER root

# Install kubectl + curl + python
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    python3 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl (stable)
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# --- Marketplace deployer utilities ---
RUN curl -L -o /bin/print_config.py \
      https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/src/commands/print_config.py \
    && curl -L -o /usr/bin/config_helper.py \
      https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/src/lib/config_helper.py \
    && curl -L -o /usr/bin/schema_values_common.py \
      https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/src/lib/schema_values_common.py \
    && chmod +x /bin/print_config.py

# Copy envsubst libs from builder
COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst
COPY --from=builder /usr/lib/x86_64-linux-gnu/libintl.so* /usr/lib/x86_64-linux-gnu/

# --- deploy scripts ---
COPY --chmod=755 deployer/deploy.sh /bin/deploy.sh
COPY --chmod=755 deployer/deploy_with_tests.sh /bin/deploy_with_tests.sh

# --- schema + manifests ---
COPY deploy/schema.yaml /data/schema.yaml
COPY deploy/ /data/
COPY docs/ /data/docs/

USER 1001
ENTRYPOINT ["/bin/deploy_with_tests.sh"]
