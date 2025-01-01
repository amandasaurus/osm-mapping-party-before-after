# Mapping party before–after

Make a image of OSM data of an area from 2 dates, showing what was changed.

You can either install the necessary dependencies on your computer or run the script via Docker (both via MyBinder or in a local container).

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/amandasaurus/osm-mapping-party-before-after/main?labpath=make-images.ipynb)

## Making a local Installation

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

## Use via Docker or MyBinder

If you do not want to install the whole pipeline yourself, you can run this setup in a Docker container that is ready-to-use and that can also run in the free-to-use open source cloud infrastructure of _MyBinder_. 

If you want to use the _MyBinder_ version, [click here and wait a bit](https://mybinder.org/v2/gh/amandasaurus/osm-mapping-party-before-after/main?labpath=make-images.ipynb). This will launch the version online in a virtual machine and lets you interact with the code through a small Python notebook that will launch automatically and contains all necessary instructions.

The MyBinder version has two drawbacks: 1. You will have to upload the OSM history file (_\*.osh.pbf_) into the container. Depending on the region of interest these can be quite large. 2. Creating the maps will take longer, as other external downloads will have to be downloaded on the fly. See [this blog post for more details](https://tzovar.as/map-comparisons/).

If you want to run the Docker image on your own computer, you can find the necessary [image is available on the GitHub Container Registry under `amandasaurus/osm-mapping-party-before-after`](https://github.com/amandasaurus/osm-mapping-party-before-after/pkgs/container/osm-mapping-party-before-after). 

### Building the Docker container from scratch

Alternatively, you can also build the container locally if you want to make changes to it/improve it: We start by cloning this repository:

```bash
git clone --recurse-submodules https://github.com/amandasaurus/osm-mapping-party-before-after
cd osm-mapping-party-before-after
git submodule init
git submodule update
```
Then we build the image that is specified in the `Dockerfile`, picking a name for the image, e.g. `before_after_builder`.
Depending on how you installed Docker, you might have to run `sudo` for each `docker` command.

 ```bash
docker build -t before_after_builder .
```

This step needs to be run only once, and it can take a few minutes as it will download and build all the dependencies needed. 

#### Running the container locally

Once the step is finished, you can launch the container like so:

```bash
./docker_run.sh before_after_builder /full/path/to/in-out-dir/ 
```

The command takes two parameters:

1. the name of the container (e.g. as specified during the `docker build` step)
2. a full path to a directory you want to use for accessing and writing files to from the container (i.e. input and output files). Depending on how you installed/run Docker, this folder might need full read/write permissions for other users (e.g. run `chmod 777`). 

The `docker_run.sh` command will then launch the container itself, including the necessary postgres database and the notebook interface. It will also create two virtual docker volumes (named `pgdata` and `osm_data`). These volumes are used to store external data, i.e. the database contents and the `openstreetmap-carto` external files, so that subsequent launches are faster than the initial one.

After running the `./docker_run.sh` command you will see a lot of text running by while the container sets itself up. At the end of this, you should see this: 

```
To access the server, open this file in a browser:
        file:///home/postgres/.local/share/jupyter/runtime/jpserver-1-open.html
    Or copy and paste one of these URLs:
        http://1ce38bef580f:8888/tree?token=asecrettokenwithlotsofcharacters
        http://127.0.0.1:8888/tree?token=asecrettokenwithlotsofcharacters
```

Clicking on the `http://127.0.0.1:8888/tree?…` link will open the notebook interface in your web-browser, where you can open the `make-images.ipynb` notebook, which will have all the necessary instructions to get started.

## Usage of `make.sh` without the container

If you have tile-building setup on your computer, you can run `make.sh` without Docker, following these steps:

1. Download an OSM history file (`.osh.pbf`) e.g. from [Geofabrik's internal download server](https://osm-internal.download.geofabrik.de/?landing_page=true). You will need to log in with an OSM account.
1. Calculate the `BBOX` with [BBoxFinder.com](http://bboxfinder.com/).
    1. *Draw a rectangle*
    1. Copy the *Box* value
    1. Make sure coordinates are in `long/lat` format (can be changed in the bottom-right)
1. Run the following command:
    ```bash
    ./make.sh OSM_HISTORY_FILE.osh.pbf BEFORE_TIME AFTER_TIME BBOX MIN_ZOOM MAX_ZOOM
    ```
    The `BEFORE_TIME` & `AFTER_TIME` are ISO 8601 timestamps.

## Example output

![Example](sample.png)

## Copyright & Licence

Copyright © 2021, Affero GPL v3+ (see [LICENCE](./LICENCE)). Project is [`osm-mapping-party-before-after` on GitHub](https://github.com/amandasaurus/osm-mapping-party-before-after)
