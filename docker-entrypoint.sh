#!/bin/sh
set -e

if [ "$(printf %c "$1")" = '-' ]; then
  set -- /sbin/tini -- make "$@"
elif [ "$1" = "make" ]; then
  set -- /sbin/tini -- "$@"
fi

exec "$@"
