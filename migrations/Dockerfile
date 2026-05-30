FROM daytonaio/daytona-api

COPY entrypoint.sh /migrate.sh
RUN chmod +x /migrate.sh

ENTRYPOINT ["/migrate.sh"]
