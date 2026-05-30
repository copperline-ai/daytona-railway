FROM daytonaio/daytona-runner

# Update insecure registry to point to Railway internal registry
RUN mkdir -p /etc/docker && echo '{"insecure-registries": ["registry.railway.internal:6000"]}' > /etc/docker/daemon.json
