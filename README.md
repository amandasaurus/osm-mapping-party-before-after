# Mapping before & after

Make a image of data of an area in OSM with data from 2 dates, showing what was changed before & after

## Installation

Follow the [`openstreetmap-carto` installation instructions](https://github.com/gravitystorm/openstreetmap-carto/blob/master/INSTALL.md), first.

## Usage

First download an OSM history from, e.g. from [Geofabrik's Download service](https://osm-internal.download.geofabrik.de/). You will need to log in with an OSM account.

A `BBOX` can be can be calculated with [BBoxFinder.com](http://bboxfinder.com/).

The `BEFORE_TIME` & `AFTER_TIME` are ISO timestamps.

```
./make.sh OSM_HISTORY_FILE.osh.pbf BEFORE_TIME AFTER_TIME BBOX MIN_ZOOM MAX_ZOOM
```

## Example

![Example](sample.png)

## Copyright & Licence

Copyright © 2021, Affero GPL v3+ (see [LICENCE](./LICENCE)). Project is [`osm-mapping-party-before-after` on GitHub](https://github.com/amandasaurus/osm-mapping-party-before-after)
