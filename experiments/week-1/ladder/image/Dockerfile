# The ladder image: plain Claude Code for experiments 0 and 2 to 6, plus the
# tools the layers add (Serena, code-graph-rag, archify, CodeBoarding).
# Same Claude Code version and base image as experiment 1's open run.
#
# What a run loads is decided at start-up: ladder-entrypoint (as root) builds
# /etc/claude-code from the floor and the layers named in LADDER_LAYERS, then
# starts Claude Code as the node user. The repository's own agent
# configuration (hooks, settings, .mcp.json, skills) never loads.
#
# Versions match the earlier toolkit and the het-2 specification (appendix B).

ARG UV_VERSION=0.12.18
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv
# JDK 21: CodeBoarding's Java language server refuses anything older.
FROM eclipse-temurin:21-jdk AS jdk21

FROM node:22-bookworm

ARG CLAUDE_CODE_VERSION=2.1.281
ARG SERENA_VERSION=1.7.0
ARG CGR_VERSION=0.0.945
ARG CODEBOARDING_VERSION=0.14.4
ARG ARCHIFY_REF=9e35d2b0b39b155553ba9fcfe0b4f2a5198dd993

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# JDK 17 for Maven's package (JDK 21 is added below as the default), Maven, search tools.
# setpriv (util-linux) drops from root to node after the layers are assembled.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-17-jdk-headless maven ripgrep jq tree python3 util-linux \
 && git config --system --add safe.directory '*' \
 && rm -rf /var/lib/apt/lists/*
RUN ln -sfn "$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")" /usr/lib/jvm/ladder-default
ENV JAVA_HOME=/usr/lib/jvm/ladder-default

COPY --from=uv /uv /uvx /usr/local/bin/
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" && npm cache clean --force

USER node
WORKDIR /home/node
ENV PATH=/home/node/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    UV_PYTHON_PREFERENCE=only-managed \
    UV_LINK_MODE=copy

# Python tools. code-graph-rag needs the pre-2.0 MCP SDK.
RUN uv tool install -p 3.13 "serena-agent==${SERENA_VERSION}" \
 && UV_TORCH_BACKEND=cpu uv tool install -p 3.12 "code-graph-rag[treesitter-full,ast-grep]==${CGR_VERSION}" \
      --with "mcp>=1.28.1,<2" \
 && uv tool install -p 3.12 "codeboarding==${CODEBOARDING_VERSION}" \
 && uv cache clean

# Serena: write its config, keep per-project data in the cache volume, and
# download the Java language server now so the first run doesn't wait for it.
COPY --chown=node image/serena-prewarm /tmp/serena-prewarm
RUN serena init \
 && sed -i \
      -e 's|^web_dashboard_open_on_launch:.*|web_dashboard_open_on_launch: false|' \
      -e 's|^project_serena_folder_location:.*|project_serena_folder_location: "/home/node/.cache/serena/$projectFolderName/.serena"|' \
      /home/node/.serena/serena_config.yml \
 && CODEBOARDING_TELEMETRY=false DO_NOT_TRACK=1 codeboarding-setup \
 && bash /tmp/serena-prewarm \
 && rm -f /tmp/serena-prewarm

# CodeBoarding 0.14.4 downloads an x86-64 tokei on every Linux machine, which
# fails on ARM (Apple Silicon): "rosetta error: failed to open elf at
# /lib64/ld-linux-x86-64.so.2" (seen 18 October). On ARM, put tokei's own
# aarch64 build in its place. CodeBoarding reinstalls only when its version or
# tool list changes, so the replacement stays. Its x86-64 gopls is used only
# for Go code and is left alone.
ARG TOKEI_VERSION=v12.1.2
ARG TOKEI_ARM64_SHA256=ef514fd12cfc3ee2d1725e5ecb866ee1123163004879ec285b22f3323389ebe2
RUN if [ "$(uname -m)" = aarch64 ]; then \
      curl -fsSL -o /tmp/tokei.tgz \
        "https://github.com/XAMPPRocky/tokei/releases/download/${TOKEI_VERSION}/tokei-aarch64-unknown-linux-gnu.tar.gz" \
      && echo "${TOKEI_ARM64_SHA256}  /tmp/tokei.tgz" | sha256sum -c - \
      && tar xzf /tmp/tokei.tgz -C /tmp \
      && install -m 0755 /tmp/tokei /home/node/.codeboarding/servers/bin/linux/tokei \
      && rm -f /tmp/tokei.tgz /tmp/tokei; \
    fi \
 && /home/node/.codeboarding/servers/bin/linux/tokei --version

# archify: its skill folder at the pinned commit. Experiment 6 copies it into
# the managed skills; the CLI works in every run.
USER root
RUN mkdir -p /tmp/archify /opt \
 && cd /tmp/archify \
 && git init -q && git remote add origin https://github.com/tt-a1i/archify.git \
 && git fetch -q --depth 1 origin "${ARCHIFY_REF}" && git checkout -q FETCH_HEAD \
 && cp -r /tmp/archify/archify /opt/archify \
 && rm -rf /tmp/archify \
 && node /opt/archify/bin/archify.mjs doctor

# JDK 21 as the default Java (CodeBoarding needs 21 or later; the earlier
# toolkit also ran Serena on 21). Copied this late so the slow layers above
# stay cached. JDK 17 from apt stays installed for Maven's package.
COPY --from=jdk21 /opt/java/openjdk /opt/java/openjdk-21
RUN ln -sfn /opt/java/openjdk-21 /usr/lib/jvm/ladder-default

COPY image/floor/ /opt/ladder/floor/
COPY image/ladder-entrypoint image/ladder-assemble image/ladder-prepare image/ladder-mcp-call \
     image/ladder-cgr-mcp image/ladder-serena-mcp image/archify /usr/local/bin/
COPY image/cgr /usr/local/bin/cgr
# The cgr shim is the only cgr on any PATH. A login shell resets PATH to put
# ~/.local/bin first, where uv linked the real cgr and code-graph-rag; run from
# the repository, they read its rigged .env and print the fake token in their
# error (seen on 18 October). The shim and ladder-cgr-mcp call them by full path.
RUN chmod 0755 /usr/local/bin/ladder-* /usr/local/bin/archify /usr/local/bin/cgr \
 && rm -f /home/node/.local/bin/cgr /home/node/.local/bin/code-graph-rag \
 && mkdir -p /etc/claude-code /work /home/node/.claude /home/node/.cache /home/node/.m2 \
 && chown node:node /work /home/node/.claude /home/node/.cache /home/node/.m2

ENV PATH=/usr/lib/jvm/ladder-default/bin:/home/node/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CLAUDE_CONFIG_DIR=/home/node/.claude \
    DISABLE_AUTOUPDATER=1 \
    CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
    MCP_TIMEOUT=60000 \
    CGR_HOME=/home/node/.cache/cgr \
    CODEBOARDING_TELEMETRY=false \
    DO_NOT_TRACK=1 \
    ARCHIFY_UPDATE_CHECK_DISABLED=1 \
    HF_HUB_DISABLE_TELEMETRY=1

# Starts as root only to write /etc/claude-code; Claude Code runs as node.
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/ladder-entrypoint"]
CMD ["claude"]
