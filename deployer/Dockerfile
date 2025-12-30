FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst/onbuild

# Copy deploy scripts expected by Marketplace
COPY --chmod=755 deployer/deploy.sh /bin/deploy.sh
COPY --chmod=755 deployer/deploy_with_tests.sh /bin/deploy_with_tests.sh

# Schema + values
COPY deploy/schema.yaml /data/schema.yaml
COPY deploy/test-values.yaml /data/test-values.yaml

# Manifests (envsubst deployer expects manifests here; you can keep your structure)
COPY deploy/manifest/ /data/manifest/

# Params template (used by envsubst in deploy.sh)
COPY deploy/params.env /data/params.env.template

# Optional docs
COPY docs/ /data/docs/

USER 1001
ENTRYPOINT ["/bin/deploy_with_tests.sh"]
