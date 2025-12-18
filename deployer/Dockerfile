FROM bitnami/kubectl:latest

COPY --chmod=755 deployer/deploy.sh /deploy.sh
COPY deploy /deploy

ENTRYPOINT ["/deploy.sh"]
