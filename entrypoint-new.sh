#!/bin/sh

export POSTGRES_PASSWORD='unused'
export PGDATA="/home/postgres/pgdata"

nohup docker-entrypoint.sh postgres &

while ! nc -z localhost 5432; do
	echo "waiting for postgres"
	sleep 1;
done;

exec "$@"
