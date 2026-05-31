FROM daytonaio/sandbox:0.5.0-slim

USER root

ARG GH_VERSION=2.93.0
ARG INFISICAL_VERSION=0.38.0
ARG RAILWAY_VERSION=4.66.0
ARG NVM_VERSION=0.40.3
ARG NODE_VERSION=22.16.0
ARG BUN_VERSION=1.2.15
ARG OPENCODE_VERSION=latest
ARG OXLINT_VERSION=latest
ARG OXFMT_VERSION=latest

ENV BUN_INSTALL=/opt/bun
ENV NVM_DIR=/usr/local/nvm
ENV PATH=${BUN_INSTALL}/bin:${PATH}

# Base tooling + git (gh dependency)
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      jq \
      python3 \
      python3-pip \
      python3-venv && \
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

# nvm + node
RUN mkdir -p "${NVM_DIR}" && \
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash && \
    . "${NVM_DIR}/nvm.sh" && \
    nvm install "${NODE_VERSION}" && \
    nvm alias default "${NODE_VERSION}"

# Bun + coding tools
RUN curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" \
      -o /tmp/bun.zip && \
    mkdir -p "${BUN_INSTALL}/bin" && \
    apt-get update && apt-get install -y --no-install-recommends unzip && \
    unzip -q /tmp/bun.zip -d /tmp && \
    mv /tmp/bun-linux-x64/bun "${BUN_INSTALL}/bin/bun" && \
    chmod +x "${BUN_INSTALL}/bin/bun" && \
    ln -sf "${BUN_INSTALL}/bin/bun" /usr/local/bin/bun && \
    rm -rf /tmp/bun.zip /tmp/bun-linux-x64 && \
    apt-get purge -y --auto-remove unzip && \
    rm -rf /var/lib/apt/lists/*

# Coding agent and format/lint tools via bun (no npm global installs)
RUN bun add --global "opencode-ai@${OPENCODE_VERSION}" "oxlint@${OXLINT_VERSION}" "oxfmt@${OXFMT_VERSION}"

# Smoke check toolchain in-image
RUN /bin/bash -lc '. "${NVM_DIR}/nvm.sh" && node --version' && \
    bun --version && \
    opencode --version && \
    oxlint --version && \
    oxfmt --version && \
    python3 --version && \
    jq --version

# Default opencode config: Vercel AI Gateway provider + DeepSeek 3.2 / MiniMax 2.5.
# API key is supplied at runtime via the AI_GATEWAY_API_KEY env var (never baked in).
COPY opencode.json /home/daytona/.config/opencode/opencode.json
RUN chown -R daytona:daytona /home/daytona/.config

USER daytona
