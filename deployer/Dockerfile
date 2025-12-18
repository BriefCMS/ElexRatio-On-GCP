FROM bitnami/kubectl:1.29

COPY deploy.sh /deploy.sh
COPY deploy /deploy

RUN chmod +x /deploy.sh

ENTRYPOINT ["/deploy.sh"]
