#!/bin/bash

# run docker with correct minimal settings to mount 
# a) postgres db 
# b) opencarto data directory
# c) import/export directory for files
# and also use correct user etc

# Requires 1 parameters: 1. name of the docker image, 2. full path to input/output directory
# depending on your setup, the input/output directory needs to have `chmod 777` on the directory to work

IMAGE_NAME=$1
OUTPUT_DIR=$2


docker run --rm -e POSTGRES_PASSWORD="unused" -v pgdata:/home/postgres/pgdata -v osm_data:/home/postgres/openstreetmap-carto/data -v $OUTPUT_DIR:/home/postgres/external --name map-before-after -p 8888:8888 $IMAGE_NAME jupyter notebook --NotebookApp.default_url=/lab/ --ip=0.0.0.0 --port=8888
