# Mapping party before–after

Make a image of OSM data of an area from 2 dates, showing what was changed.

## Installation

1. *On macOS:* [install Homebrew](https://brew.sh/#:~:text=Install%20Homebrew)
1. [Install `pipx`](https://pipx.pypa.io/stable/installation/#installing-pipx)
1. [Install `openstreetmap-carto`](https://github.com/gravitystorm/openstreetmap-carto/blob/4ec2dc9391c411e124c78b3ba1aad9173fea20cb/INSTALL.md)
1. Install [`osmium-tool`](https://github.com/osmcode/osmium-tool)
1. [Install Mapnik](https://github.com/mapnik/mapnik/blob/master/INSTALL.md#source-build)
1. [Install `python-mapnik`](https://github.com/mapnik/python-mapnik#building-from-source)
1. Install [`nik4`](https://github.com/Zverik/Nik4) (used to generate an image with the [`openstreetmap-carto` map style](https://github.com/gravitystorm/openstreetmap-carto/)):
   ```bash
   pipx install nik4
   ```
1. [Install GraphicsMagick](http://www.graphicsmagick.org/README.html#id4)
1. *On macOS:* replace built-in `coreutils` commands with the GNU ones:
   ```bash
   brew install coreutils
   export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH
   ```
1. Clone this repo:
   ```bash
   git clone --recurse-submodules https://github.com/amandasaurus/osm-mapping-party-before-after
   cd osm-mapping-party-before-after
   ```

### Install & use via Docker image

Alternatively, if you do not want to install the whole pipeline yourself, you can run this setup in a Docker container that is ready to use.
We start, by cloning this repository:

```bash
git clone --recurse-submodules https://github.com/amandasaurus/osm-mapping-party-before-after
cd osm-mapping-party-before-after
   ```
Then we build the image that is specified in the `Dockerfile`, picking a name for the image, e.g. `before_after_builder`.
Depending on how you installed Docker, you might have to run `sudo` for each `docker` command.

 ```bash
`docker build -t before_after_builder
```

This step needs to be run only once, and it can take a few minutes as it will download and build all the dependencies needed. 
Once the step is finished, you can launch the container like so:

```bash
./docker_run.sh before_after_builder /full/path/to/in-out-dir/ 
```

The command takes two parameters:

1. the name of the container (as specified above)
2. a full path to a directory you want to use for accessing and writing files to from the container (i.e. Input and output files). Depending on how you installed/run Docker, this folder might need full read/write permissions for other users (e.g. run `chmod 777`). 

The `docker_run.sh` command will launch the container itself, including the necessary postgres database etc.
It will also create two virtual docker volumes (named `pgdata` and `osm_data`). 
These volumes are used to store external data, i.e. the database contents and the `openstreetmap-carto` external files.

Once the docker container is running, you can connect into it to get a bash inside to run the commands as outlined below using:

```bash
docker exec -ti map-before-after before_after_builder
```

The resulting shell puts you into the equivalent of the root of this repository, in a folder called `/workdir`. From there you can use this repository as outlined below. 

All output files are saved in the `/workdir` by default, you can from there move them into `/workdir/output` inside the container to access files on your host operating system.

## Usage

1. Download an OSM history file (`.osh.pbf`) e.g. from [Geofabrik's internal download server](https://osm-internal.download.geofabrik.de/?landing_page=true). You will need to log in with an OSM account.
1. Calculate the `BBOX` with [BBoxFinder.com](http://bboxfinder.com/).
    1. *Draw a rectangle*
    1. Copy the *Box* value
1. Run the following command:
    ```bash
    ./make.sh OSM_HISTORY_FILE.osh.pbf BEFORE_TIME AFTER_TIME BBOX MIN_ZOOM MAX_ZOOM
    ```
    The `BEFORE_TIME` & `AFTER_TIME` are ISO 8601 timestamps.

## Example output

![Example](sample.png)

## Copyright & Licence

Copyright © 2021, Affero GPL v3+ (see [LICENCE](./LICENCE)). Project is [`osm-mapping-party-before-after` on GitHub](https://github.com/amandasaurus/osm-mapping-party-before-after)
