# NanoClaw host runtime. Source, data, and node_modules come from a bind
# mount at the same path as on the Docker host — this image only provides
# Node, pnpm, and the Docker CLI (talks to the mounted docker.sock).
FROM docker:27-cli AS dockercli

FROM node:22-bookworm-slim

COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates git python3 make g++ tini \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

COPY deploy/entrypoint.sh /usr/local/bin/nanoclaw-entrypoint
RUN chmod +x /usr/local/bin/nanoclaw-entrypoint

WORKDIR /home/matty/nanoclaw
ENV NODE_ENV=production

ENTRYPOINT ["tini", "--", "nanoclaw-entrypoint"]
CMD ["node", "dist/index.js"]
