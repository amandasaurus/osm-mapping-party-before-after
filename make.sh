#! /bin/bash
set -o errexit -o nounset -o pipefail

if [ $# -ge 1 ] && [ "$1" = "-h" ] ; then
	cat <<-END
	Usage: $0 INPUT.osh.pbf BEFORETIME AFTERTIME BBOX [MIN_ZOOM] [MAX_ZOOM] [NUM_FRAMES]

	BEFORETIME & AFTERTIME are ISO-8601 timestamps
	BBOX is a comma-separated long/lat bounding box (left,bottom,right,top) and can be found via http://bboxfinder.com/
	MIN_ZOOM and MAX_ZOOM are optional zoom levels (default: 6 and 12)
	NUM_FRAMES is the number of frames to generate for the GIF (default: 2)
	END
	exit 0
fi

INPUT_FILE=$(realpath "${1:?Arg 1 should be the path to the pbf file}")
TIME_BEFORE=${2:?Arg 2 should be the ISO timestamp for the before time}
TIME_AFTER=${3:?Arg 3 should be the ISO timestamp for the after time}
BBOX=${4:-"world"}
BBOX_COMMA="${BBOX// /,}"
BBOX_SPACE="${BBOX//,/ }"
MIN_ZOOM=${5:-6}
MAX_ZOOM=${6:-12}
NUM_FRAMES=${7:-2}

# for planet-latest.osm.obf we calculate the "planet" part
PREFIX=$(basename "$INPUT_FILE")
PREFIX=${PREFIX%%.osh.pbf}
PREFIX=${PREFIX%%-latest}
PREFIX=${PREFIX%%-internal}
PREFIX=${PREFIX//-/_}

ROOT="$(realpath "$(dirname "$0")")"
cd "$ROOT" || exit

PBF_FILE="$(realpath "$PREFIX.$BBOX.osh.pbf")"
if [ "$INPUT_FILE" -nt "$PBF_FILE" ] ; then
  echo "Extracting the OSM history for just this bounding box $BBOX"
  NEWFILE=$(mktemp -p . "tmp.extract.${PREFIX}.XXXXXX.osm.pbf")
  osmium extract --with-history --overwrite -o "$NEWFILE" --bbox "$BBOX_COMMA" "$INPUT_FILE"
  mv "$NEWFILE" "$PBF_FILE"
fi

if [ ! -s "$ROOT/openstreetmap-carto/node_modules/.bin/carto" ] ; then
  cd "$ROOT/openstreetmap-carto"
  echo "Installing carto into $ROOT/openstreetmap-carto/node_modules with npm..."
  npm init -y
  npm install carto -q
fi

if [ ! -s "$ROOT/openstreetmap-carto/project.xml" ] ; then
  cd "$ROOT"
  if [ ! -e "$ROOT/openstreetmap-carto" ] ; then
    git submodule update
  fi
  cd "$ROOT/openstreetmap-carto"
  if [ ! -s project.xml ] || [ project.mml -nt project.xml ] ; then
    TMP=$(mktemp -p . tmp.project.XXXXXX.xml)
    ./node_modules/.bin/carto -a 3.0.0 project.mml > "$TMP"
    mv "$TMP" project.xml
  fi
fi

if [ "$(psql -At -c "select count(*) from pg_database where datname = 'gis';")" = "0" ] ; then
  echo "Creating gis database..."
  createdb gis
  psql -d gis -c "create extension postgis;"
  psql -d gis -c "create extension hstore;"
fi

if [ ! -e "$ROOT/openstreetmap-carto/data/.external-data-done" ] ; then
  cd "$ROOT/openstreetmap-carto/"
  echo "Downloading external datasets..."
  ./scripts/get-external-data.py
  touch data/.external-data-done
  cd "$ROOT"
fi

# Function to generate ISO-8601 timestamps between two times
generate_timestamps() {
 local start_time=$1
 local end_time=$2
 local num_stops=$3
 python3 - <<END
import datetime
from dateutil import parser
start_time = parser.isoparse("$start_time")
end_time = parser.isoparse("$end_time")
delta = (end_time - start_time) / ($num_stops - 1)
timestamps = [start_time + i * delta for i in range($num_stops)]
for ts in timestamps:
    ts = ts.replace(microsecond=0)
    print(ts.isoformat().replace("+00:00", "Z"))
END
}

# Generate timestamps
TIMESTAMPS=$(generate_timestamps "$TIME_BEFORE" "$TIME_AFTER" "$NUM_FRAMES")

# Process each timestamp
for TIME in $TIMESTAMPS; do
  FILENAME="$(realpath "${PREFIX}.$TIME.$BBOX_COMMA.osm.pbf")"
  if [ "$PBF_FILE" -nt "$FILENAME" ] ; then
    NEWFILE=$(mktemp -p . tmp.time.XXXXXX.osm.pbf)
    echo "Extracting data for $TIME..."
    osmium time-filter --overwrite -o "$NEWFILE" "$PBF_FILE" "$TIME"
    mv "$NEWFILE" "$FILENAME"
  fi

  if [ "$FILENAME" -nt "$ROOT/.$PREFIX.$TIME.$BBOX_COMMA.generated" ] ; then
    cd "$ROOT/openstreetmap-carto"
    echo "Importing data for $TIME..."
    osm2pgsql -G --hstore --style openstreetmap-carto.style --tag-transform-script openstreetmap-carto.lua -d gis "$FILENAME"
    psql -d gis -f indexes.sql
    touch "$ROOT/.$PREFIX.$TIME.$BBOX_COMMA.generated"
  fi

  cd "$ROOT"
  for ZOOM in $(seq "$MIN_ZOOM" "$MAX_ZOOM") ; do
    if [ "$ROOT/.$PREFIX.$TIME.$BBOX_COMMA.generated" -nt "$PREFIX.$TIME.$BBOX_COMMA.z${ZOOM}.png" ] ; then
      echo "Generating zoom ${ZOOM} at time ${TIME}"
      GENERATED="$PREFIX.$TIME.$BBOX_COMMA.z${ZOOM}.png"
      nik4.py openstreetmap-carto/project.xml "$GENERATED" -b $BBOX_SPACE -z "$ZOOM" || break
      # Add padding to the bottom of the image to make space for the attribution
      NEW_PADDED="$(mktemp tmp.XXXXXX.padded.png)"
      gm convert "$GENERATED" -background white -gravity south -extent -0-30 "$NEW_PADDED" || break
      # Add the attribution and timestamp
      NEW_ATTRIBUTION="$(mktemp tmp.XXXXXX.attribution.png)"
      gm convert "$NEW_PADDED" -font Courier -pointsize 20 -fill black \
                               -gravity southwest -draw "text 5,5 '${TIME}'" \
                               -gravity southeast -draw "text 5,5 'Data © OpenStreetMap contributors, ODbL'" \
                               "$NEW_ATTRIBUTION" || break
      mv "$NEW_ATTRIBUTION" "$GENERATED"
      rm "$NEW_PADDED"
    fi
  done
done

cd "$ROOT"
for ZOOM in $(seq "$MIN_ZOOM" "$MAX_ZOOM") ; do
  # Generate comparison images of start and end times for each zoom level
  NEW_PNG="progress.$PREFIX.$TIME_BEFORE.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png"
  BEFORE="$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png"
  AFTER="$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png"
  if [ ! -s "$BEFORE" ] || [ ! -s "$AFTER" ] ; then
    continue
  fi
  echo "Generating comparison image for zoom $ZOOM"

  if [ "$BEFORE" -nt "$NEW_PNG" ] || [ "$AFTER" -nt "$NEW_PNG" ] ; then
    TMP="$(mktemp tmp.XXXXXX.png)"
    gm montage -geometry +0+0 "$BEFORE" "$AFTER" "$TMP"
    gm convert "$TMP" -background white -label "Data © OpenStreetMap contributors, ODbL" -gravity center -append "$NEW_PNG"
    rm "$TMP"
  fi

  if [ "$BEFORE" -nt "$NEW_PNG" ] || [ "$AFTER" -nt "$NEW_PNG" ] ; then
    gm montage -geometry +0+0 "$BEFORE" "$AFTER" "$NEW_PNG"
  fi

  # Generate a GIF using the frames
  NEW_GIF="progress.$PREFIX.$TIME_BEFORE.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.gif"
	if [ "$BEFORE" -nt "$NEW_GIF" ] || [ "$AFTER" -nt "$NEW_GIF" ] ; then
    gm convert -delay 50 "$PREFIX".*."$BBOX_COMMA".z"$ZOOM".png "$NEW_GIF"
  fi
done
