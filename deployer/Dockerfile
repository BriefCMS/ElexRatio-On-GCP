
FROM bitnami/kubectl:latest

COPY --chmod=755 deployer/deploy.sh /deploy.sh

COPY deploy/schema.yaml /data/schema.yaml
COPY deploy/ /data/  
COPY deployer/ /data/
COPY docs/ /data/docs/


ENTRYPOINT ["/deploy.sh"]
