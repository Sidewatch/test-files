# syntax=docker/dockerfile:1.7
# escape=\
# check=error=true

# ── Comments ──
# Comment line. TODO: pin digests. FIXME: slim the runtime image.

# ── Global arguments ──
ARG NODE_VERSION=20
ARG BASE_IMAGE=node
ARG REGISTRY

# ── Build stage ──
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE}:${NODE_VERSION}-alpine AS build
LABEL org.opencontainers.image.title="Acme Warehouse" \
      org.opencontainers.image.vendor="Acme Inc." \
      maintainer="ops@example.com"

ARG APP_ENV=production
ENV NODE_ENV=$APP_ENV \
    PORT=3000 \
    WAREHOUSE_HOME=/opt/warehouse
ENV GREETING "hello world"

WORKDIR /opt/warehouse
SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

# Copy manifests first for layer caching
COPY package.json package-lock.json ./
COPY --chown=node:node --chmod=0644 config/*.json ./config/
ADD https://example.com/assets/labels.tar.gz /tmp/labels.tar.gz
ADD --checksum=sha256:0000000000000000000000000000000000000000000000000000000000000000 https://example.com/x.txt /tmp/

# RUN: shell form, exec form, heredoc and mounts
RUN apk add --no-cache curl bash \
    && npm ci --omit=dev \
    && npm cache clean --force
RUN ["/bin/sh", "-c", "echo exec form"]
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=secret,id=npmrc,target=/root/.npmrc \
    --network=none \
    npm run build
RUN <<EOT
#!/bin/sh
set -e
echo "building $APP_ENV"
mkdir -p /opt/warehouse/dist
EOT
COPY <<EOF /opt/warehouse/banner.txt
Acme Warehouse
EOF

COPY . .
RUN npm run build

# ── Runtime stage ──
FROM gcr.io/distroless/nodejs20-debian12:nonroot AS runtime
COPY --from=build --chown=nonroot:nonroot /opt/warehouse/dist /app
COPY --from=build /opt/warehouse/node_modules /app/node_modules

WORKDIR /app
USER nonroot:nonroot
EXPOSE 3000 3001/tcp 9229/udp
VOLUME ["/var/lib/warehouse", "/var/log/warehouse"]
VOLUME /data
STOPSIGNAL SIGTERM
ONBUILD RUN echo "child image build"

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["node", "healthcheck.js"]

ENTRYPOINT ["node", "--enable-source-maps"]
CMD ["server.js", "--port", "3000"]

# ── Alternative shell-form forms ──
FROM scratch AS minimal
CMD echo "shell form"
ENTRYPOINT exec /app/run
HEALTHCHECK NONE
MAINTAINER Acme Ops <ops@example.com>
FROM busybox:1.36@sha256:0000000000000000000000000000000000000000000000000000000000000000 AS pinned

# ── Further instructions and flags ──
FROM --platform=linux/arm64 --platform=$TARGETPLATFORM alpine:3.19 AS extras
ARG TARGETARCH TARGETOS=linux
ARG VERSION=1.0.0 \
    CHANNEL=stable
ENV A=1 B="two words" C='three words' D=$A-${B}
ENV PATH="/opt/warehouse/bin:${PATH}" \
    LANG=C.UTF-8
LABEL version="${VERSION}" description="Multi-line \
label value"

# Expansion forms
WORKDIR /opt/${CHANNEL:-stable}/app
ENV FALLBACK=${UNSET_VAR:-default} ALTERNATE=${CHANNEL:+set} LITERAL=\$NOT_EXPANDED ESCAPED='$ALSO_LITERAL'
RUN echo "arch=${TARGETARCH} os=${TARGETOS} pid=$$ home=$HOME"

# Instruction variants
ADD --keep-git-dir=true --link https://example.com/repo.git#main /src
ADD --chown=1000:1000 --chmod=755 ["archive.tar.gz", "/opt/"]
COPY --link --from=build /opt/warehouse/dist/ /app/
COPY --from=docker.io/library/busybox:latest /bin/busybox /bin/busybox
COPY ["file with spaces.txt", "/dest/"]
RUN --mount=type=bind,source=.,target=/src,rw --mount=type=tmpfs,target=/tmp,size=64m \
    --mount=type=ssh --security=insecure --network=host \
    make -C /src install
RUN apt-get update \
    # comments may appear inside continuation lines
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
    && rm -rf /var/lib/apt/lists/*
RUN <<-EOT bash -ex
	echo "tab-indented heredoc"
	ls -l
EOT
RUN <<'EOT'
echo 'quoted heredoc: $NOT_EXPANDED'
EOT
RUN python3 <<PY
print("inline python heredoc")
PY
COPY <<-"EOF" /etc/motd
	Quoted heredoc destination
EOF
EXPOSE 80/tcp 443 8000-8010/udp
USER 1000
USER nobody:nogroup
VOLUME ["/data"]
STOPSIGNAL 9
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]
ONBUILD COPY . /app
ONBUILD ARG LATE_BOUND
HEALTHCHECK --interval=5m --start-interval=2s CMD curl -f http://localhost/ || exit 1
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "--"]
CMD ["--help"]
CMD [ "sh" , "-c" , "echo done" ]
FROM scratch
FROM alpine AS "quoted-stage"
FROM ${REGISTRY:-docker.io}/library/${BASE_IMAGE:-alpine}:${TAG:-latest}
