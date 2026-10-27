# Week 2's ladder image: plain Claude Code, the same version and floor as Week 1,
# without Week 1's code navigation tools (Serena, code-graph-rag, CodeBoarding),
# with archify for e7b's diagram, and with the Chrome DevTools MCP server.
#
# Built with the week-2 folder as context. ladder-entrypoint (as root) builds /etc/claude-code
# from the floor and the layers named in LADDER_LAYERS, then starts Claude Code
# as the node user. The repository's own agent configuration never loads.

FROM node:22-bookworm

ARG CLAUDE_CODE_VERSION=2.1.281
ARG CHROME_DEVTOOLS_MCP_VERSION=1.11.0
ARG ARCHIFY_REF=9e35d2b0b39b155553ba9fcfe0b4f2a5198dd993

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# JDK 17 and Maven for PetClinic; python3 for the hook scripts; setpriv (util-linux)
# drops from root to node after the layers are assembled.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-17-jdk-headless maven ripgrep jq python3 util-linux \
 && git config --system --add safe.directory '*' \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "chrome-devtools-mcp@${CHROME_DEVTOOLS_MCP_VERSION}" \
 && npm cache clean --force

# archify at Week 1's pinned commit: the w2-archify layer copies its skill into the
# managed skills (ladder-assemble), and the `archify` command works in every run.
RUN mkdir -p /tmp/archify /opt \
 && cd /tmp/archify \
 && git init -q && git remote add origin https://github.com/tt-a1i/archify.git \
 && git fetch -q --depth 1 origin "${ARCHIFY_REF}" && git checkout -q FETCH_HEAD \
 && cp -r /tmp/archify/archify /opt/archify \
 && rm -rf /tmp/archify \
 && node /opt/archify/bin/archify.mjs doctor

COPY image/floor/ /opt/ladder/floor/
COPY image/ladder-entrypoint image/ladder-assemble /usr/local/bin/
COPY image/ladder-chrome-mcp image/archify /usr/local/bin/
# Week 2 has no tools to prepare; the entrypoint calls ladder-prepare only when
# LADDER_PREPARE=1, and compose sets 0.
RUN chmod 0755 /usr/local/bin/ladder-* /usr/local/bin/archify \
 && mkdir -p /etc/claude-code /work /home/node/.claude /home/node/.cache /home/node/.m2 \
 && chown node:node /work /home/node/.claude /home/node/.cache /home/node/.m2

ENV CLAUDE_CONFIG_DIR=/home/node/.claude \
    DISABLE_AUTOUPDATER=1 \
    CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
    MCP_TIMEOUT=60000 \
    CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=1 \
    DO_NOT_TRACK=1

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/ladder-entrypoint"]
CMD ["claude"]
