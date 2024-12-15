#!/bin/sh

export POSTGRES_PASSWORD='unused'
export PGDATA="/home/postgres/pgdata"

nohup docker-entrypoint.sh postgres &

exec "$@"
