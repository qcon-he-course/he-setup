# Week 3's ladder image: plain Claude Code, the same version and floor as Weeks 1
# and 2, with JDK 17 and Maven for PetClinic and the OpenSpec CLI. No browser and
# no code navigation tools. Codex CLI is installed for e15's second reviewer.
#
# Built with this folder as context. It reuses Week 1's floor and start-up
# scripts unchanged (copied into image/, as Week 2 does): ladder-entrypoint (as root) builds /etc/claude-code
# from the floor and the layers named in LADDER_LAYERS, then starts Claude Code
# as the node user. The repository's own agent configuration never loads.

FROM node:22-bookworm

ARG CLAUDE_CODE_VERSION=2.1.281
ARG OPENSPEC_VERSION=1.15.0
# The second reviewer in e15 (LADDER_AGENT=codex); 0.163.0 is of 15 October 2026.
ARG CODEX_VERSION=0.163.0

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# JDK 17 and Maven for PetClinic; python3 for the hook scripts; setpriv (util-linux)
# drops from root to node after the layers are assembled.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-17-jdk-headless maven ripgrep jq python3 util-linux \
 && git config --system --add safe.directory '*' \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "@fission-ai/openspec@${OPENSPEC_VERSION}" \
      "@openai/codex@${CODEX_VERSION}" \
 && npm cache clean --force

COPY image/floor/ /opt/ladder/floor/
COPY image/ladder-entrypoint image/ladder-assemble /usr/local/bin/
# Week 3 has no tools to prepare; the entrypoint calls ladder-prepare only when
# LADDER_PREPARE=1, and compose sets 0.
RUN chmod 0755 /usr/local/bin/ladder-* \
 && mkdir -p /etc/claude-code /work /home/node/.claude /home/node/.cache /home/node/.m2 \
 && chown node:node /work /home/node/.claude /home/node/.cache /home/node/.m2

ENV CLAUDE_CONFIG_DIR=/home/node/.claude \
    DISABLE_AUTOUPDATER=1 \
    CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
    OPENSPEC_TELEMETRY=0 \
    DO_NOT_TRACK=1

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/ladder-entrypoint"]
CMD ["claude"]
