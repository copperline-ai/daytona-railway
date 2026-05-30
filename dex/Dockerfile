FROM dexidp/dex:v2.42.0

COPY config.yaml /etc/dex/config.template.yaml
COPY entrypoint.sh /entrypoint.sh

USER root
RUN apk add --no-cache gettext && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
