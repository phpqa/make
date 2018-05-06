ARG BASE_IMAGE="docker:18.03"
ARG VERSION="4.2.1-r0"

# Build image

FROM ${BASE_IMAGE}
ARG VERSION

# Install Tini - https://github.com/krallin/tini

RUN apk add --no-cache tini

# Install GNU Make - https://pkgs.alpinelinux.org/package/edge/main/x86/make

RUN apk add --no-cache "make=${VERSION}"

# Add entrypoint script

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Package container

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["make"]

