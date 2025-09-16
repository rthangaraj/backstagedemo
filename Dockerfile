FROM node:20-bookworm-slim

# Install sqlite3 and TechDocs dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      libsqlite3-dev \
      python3 \
      python3-pip \
      python3-venv \
      build-essential && \
    yarn config set python /usr/bin/python3

# Set up virtual environment for mkdocs-techdocs-core
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip3 install mkdocs-techdocs-core==1.1.7

# Switch to non-root user
WORKDIR /app
RUN chown node:node /app
USER node

# Set production environment
ENV NODE_ENV=production

# Copy Yarn configuration and patches
COPY --chown=node:node .yarn/ .yarn/
COPY --chown=node:node .yarnrc.yml ./

# Copy lockfile and root package.json
COPY --chown=node:node yarn.lock package.json ./

# Copy workspace skeleton (only package.json files)
COPY --chown=node:node packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

# Install production dependencies using Yarn 4 best practice
RUN --mount=type=cache,target=/tmp/yarn-cache,sharing=locked \
    yarn workspaces focus --all --production

# Copy backend bundle and config files
COPY --chown=node:node packages/backend/dist/bundle.tar.gz app-config*.yaml ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Start the backend
CMD ["node", "packages/backend", "--config", "app-config.yaml"]
