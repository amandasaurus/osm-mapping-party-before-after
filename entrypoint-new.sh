#!/bin/sh

export POSTGRES_PASSWORD='unused'

nohup docker-entrypoint.sh postgres &

exec "$@"
