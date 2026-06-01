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

# Base tooling + git (gh dependency). Also generate the en_US.UTF-8 locale — the base
# image sets LANG/LC_ALL=en_US.UTF-8 but ships no locale data, so every bash invocation
# prints "setlocale: cannot change locale (en_US.UTF-8)" (noise in command output).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      jq \
      locales \
      python3 \
      python3-pip \
      python3-venv && \
    sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
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

# Lint/format tools via bun. bun stays available for general use; we don't route
# the agent CLIs through it. Symlinked into /usr/local/bin (see PATH note below).
RUN bun add --global --trust "oxlint@${OXLINT_VERSION}" "oxfmt@${OXFMT_VERSION}" && \
    ln -sf "${BUN_INSTALL}/bin/oxlint" /usr/local/bin/oxlint && \
    ln -sf "${BUN_INSTALL}/bin/oxfmt" /usr/local/bin/oxfmt

# Agent CLIs (opencode / claude / cursor `agent`), installed the SAME way Paperclip
# installs them in sandboxes, and placed on /usr/local/bin so `command -v` resolves
# them in Daytona's login-shell exec. (That exec sources /etc/profile, which resets
# PATH to /usr/local/bin:/usr/bin:/bin... — dropping /opt/bun/bin and ~/.local/bin.)
# Pre-baking means Paperclip's runtime install probe no-ops. Secrets such as
# AI_GATEWAY_API_KEY are injected at runtime via sandbox env, never baked in.

# opencode — official installer (single binary; the npm opencode-ai package is large/slow)
RUN curl -fsSL https://opencode.ai/install | bash && \
    if [ -x /root/.opencode/bin/opencode ]; then install -m 0755 /root/.opencode/bin/opencode /usr/local/bin/opencode; fi && \
    rm -rf /root/.opencode && \
    command -v opencode

# Anthropic Claude Code — npm global (matches Paperclip's claude-local adapter)
RUN bash -lc '. "${NVM_DIR}/nvm.sh" && npm install -g @anthropic-ai/claude-code' && \
    ln -sf "$(bash -lc '. "${NVM_DIR}/nvm.sh" >/dev/null 2>&1 && command -v claude')" /usr/local/bin/claude && \
    command -v claude

# Cursor agent — official installer. The installed `agent` is a wrapper that resolves
# a bundled node *relative to itself* (~/.cursor/bin/node), so it can't just be copied
# to /usr/local/bin. Install the whole tree into the daytona user's HOME; Paperclip's
# cursor adapter prepends ~/.cursor/bin (and ~/.local/bin) to PATH at runtime.
RUN HOME=/home/daytona bash -c 'curl https://cursor.com/install -fsS | bash' && \
    chown -R daytona:daytona /home/daytona/.cursor /home/daytona/.local 2>/dev/null; \
    HOME=/home/daytona /home/daytona/.local/bin/agent --version

# Smoke check toolchain in-image (agent verified in its own step above)
RUN bash -lc '. "${NVM_DIR}/nvm.sh" && node --version && claude --version' && \
    bun --version && \
    opencode --version && \
    oxlint --version && \
    oxfmt --version && \
    python3 --version && \
    jq --version

# Default opencode config: Vercel AI Gateway provider + DeepSeek 3.2 / MiniMax 2.5.
# API key is supplied at runtime via the AI_GATEWAY_API_KEY env var (never baked in).
COPY opencode.json /home/daytona/.config/opencode/opencode.json

# Superpowers skills plugin for OpenCode (pre-installed for zero-latency startup)
RUN /bin/bash -lc '. "${NVM_DIR}/nvm.sh" && \
    npm install "superpowers@git+https://github.com/obra/superpowers.git" --prefix /home/daytona/.config/opencode'

RUN chown -R daytona:daytona /home/daytona/.config

USER daytona
