FROM docker
MAINTAINER Bart Reunes <metalarend@gmail.com>

RUN apk add --no-cache --quiet make

ENTRYPOINT ["make"]
CMD ["--help"]

