FROM daytonaio/sandbox:0.5.0-slim

USER root

ARG GH_VERSION=2.93.0
ARG INFISICAL_VERSION=0.38.0

# git (gh dependency) + GitHub CLI
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.deb" \
      -o /tmp/gh.deb && \
    dpkg -i /tmp/gh.deb && \
    rm /tmp/gh.deb

# Infisical CLI
RUN curl -fsSL "https://dl.cloudsmith.io/public/infisical/infisical-cli/deb/ubuntu/pool/any-version/main/i/in/infisical_${INFISICAL_VERSION}/infisical_${INFISICAL_VERSION}_linux_amd64.deb" \
      -o /tmp/infisical.deb && \
    dpkg -i /tmp/infisical.deb && \
    rm /tmp/infisical.deb

USER daytona
