FROM daytonaio/sandbox:0.5.0-slim

USER root

ARG GH_VERSION=2.93.0
ARG INFISICAL_VERSION=0.38.0
ARG RAILWAY_VERSION=4.66.0

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

# Railway CLI
RUN curl -fsSL "https://github.com/railwayapp/cli/releases/download/v${RAILWAY_VERSION}/railway-v${RAILWAY_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
      | tar -xz -C /usr/local/bin railway && \
    chmod +x /usr/local/bin/railway

# Coding agent: opencode (node 22 + npm already present in base image)
RUN npm install -g opencode-ai && \
    npm cache clean --force

# Default opencode config: Vercel AI Gateway provider + DeepSeek 3.2 / MiniMax 2.5.
# API key is supplied at runtime via the AI_GATEWAY_API_KEY env var (never baked in).
COPY opencode.json /home/daytona/.config/opencode/opencode.json
RUN chown -R daytona:daytona /home/daytona/.config

USER daytona
