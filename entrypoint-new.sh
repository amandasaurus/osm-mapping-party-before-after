#!/bin/sh

export POSTGRES_PASSWORD='unused'

docker-entrypoint.sh postgres &

exec "$@"
