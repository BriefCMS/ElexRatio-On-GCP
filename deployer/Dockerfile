FROM debian:bookworm-slim AS builder
RUN apt-get update && apt-get install -y gettext-base

FROM bitnami/kubectl:latest
USER root

COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst
COPY --from=builder /usr/lib/x86_64-linux-gnu/libintl.so* /usr/lib/x86_64-linux-gnu/

# copy deployer script to /bin (required by marketplace)
COPY --chmod=755 deployer/deploy.sh /bin/deploy.sh
RUN chmod +x /bin/deploy.sh

COPY --chmod=755 deployer/deploy_with_tests.sh /bin/deploy_with_tests.sh
RUN chmod +x /bin/deploy_with_tests.sh

# copy schema + templates
COPY deploy/schema.yaml /data/schema.yaml
COPY deploy/ /data/
COPY docs/ /data/docs/

USER 1001
ENTRYPOINT ["/bin/deploy.sh"]
