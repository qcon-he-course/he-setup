# Plain Claude Code for experiment 1's open run: no managed settings,
# so the repository's hooks and settings load once the folder is trusted.
# Same Claude Code version as het. curl is in the base image; the
# repository's hook needs it.
FROM node:22-bookworm
RUN npm install -g @anthropic-ai/claude-code@2.1.281
ENV CLAUDE_CONFIG_DIR=/home/node/.claude
USER node
WORKDIR /work
CMD ["claude"]
