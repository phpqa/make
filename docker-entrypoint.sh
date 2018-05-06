#!/bin/sh
set -e

if [ "${1:0:1}" = "-" ]; then
  set -- /sbin/tini -- make "$@"
elif [ "$1" = "make" ]; then
  set -- /sbin/tini -- "$@"
fi

exec "$@"
