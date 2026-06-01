FROM daytonaio/daytona-api:v0.171.0

COPY entrypoint.sh /migrate.sh
RUN chmod +x /migrate.sh

ENTRYPOINT ["/migrate.sh"]
