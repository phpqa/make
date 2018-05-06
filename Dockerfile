# Set defaults

ARG BASE_IMAGE="docker:18.03"
ARG VERSION="4.2.1"

# Build image

FROM ${BASE_IMAGE}
ARG VERSION
ARG INTERNAL_TAG
ARG BUILD_DATE
ARG VCS_REF

# Install Tini - https://github.com/krallin/tini

RUN apk add --no-cache tini

# Install GNU Make - https://pkgs.alpinelinux.org/package/edge/main/x86/make

RUN apk add --no-cache "make=~${VERSION}"

# Add entrypoint script

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Add image labels

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.vendor="phpqa" \
      org.label-schema.name="make" \
      org.label-schema.version="${INTERNAL_TAG}" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.url="https://github.com/phpqa/make" \
      org.label-schema.usage="https://github.com/phpqa/make/README.md" \
      org.label-schema.vcs-url="https://github.com/phpqa/make.git" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.docker.cmd="docker run --rm --volume \${PWD}:/app --workdir /app phpqa/make:${INTERNAL_TAG}"

# Package container

WORKDIR "/app"
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["make"]

