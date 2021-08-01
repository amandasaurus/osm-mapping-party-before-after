#! /bin/bash
set -o errexit -o nounset -o pipefail

if [ $# -ge 1 ] && [ "$1" = "-h" ] ; then
	cat <<-END
	Usage: $0 INPUT.osh.pbf BEFORETIME AFTERTIME BBOX
	
	TIME1 & TIME2 are ISO timestamps
	bboxes can be found via http://bboxfinder.com/
	END
	exit 0
fi

INPUT_FILE=$(realpath "${1:?Arg 1 should be the path to the pbf file}")
TIME_BEFORE=${2:?Arg 2 should be the ISO timestamp for the before time}
TIME_AFTER=${3:?Arg 3 should be the ISO timestamp for the after time}
BBOX=${4:-"world"}
# for planet-latest.osm.obf we calculate the "planet" part
PREFIX=$(basename "$INPUT_FILE")
PREFIX=${PREFIX%%.osh.pbf}
PREFIX=${PREFIX%%-latest}
PREFIX=${PREFIX%%-internal}
PREFIX=${PREFIX//-/_}
MIN_ZOOM=${5:-6}
MAX_ZOOM=${6:-12}

ROOT="$(realpath "$(dirname "$0")")"
cd "$ROOT" || exit

BBOX_COMMA="${BBOX// /,}"
BBOX_SPACE="${BBOX//,/ }"

if [ ! -s "$INPUT_FILE" ] ; then
	echo "Input file $INPUT_FILE not found" 1>&2
	exit 1
fi

if [ "$BBOX" = "world" ] ; then
	PBF_FILE="$INPUT_FILE"
else 
	PBF_FILE="$(realpath "$PREFIX.$BBOX.osh.pbf")"
	if [ "$INPUT_FILE" -nt "$PBF_FILE" ] ; then
		echo "Extracting the OSM history for just this bounding box $BBOX"
		NEWFILE=$(mktemp -p . "tmp.extract.${PREFIX}.XXXXXX.osm.pbf")
		osmium extract --with-history --overwrite -o "$NEWFILE" --bbox "$BBOX_COMMA" "$INPUT_FILE"
		mv "$NEWFILE" "$PBF_FILE"
	fi
fi

BEFORE_FILENAME="$(realpath "${PREFIX}.$TIME_BEFORE.$BBOX_COMMA.osm.pbf")"
if [ "$PBF_FILE" -nt "$BEFORE_FILENAME" ] ; then
	NEWFILE=$(mktemp -p . tmp.time1.XXXXXX.osm.pbf)
	echo "Extracting 'before' data..."
	osmium time-filter --overwrite -o "$NEWFILE" "$PBF_FILE" "$TIME_BEFORE"
	mv "$NEWFILE" "$BEFORE_FILENAME"
fi

AFTER_FILENAME="$(realpath "${PREFIX}.$TIME_AFTER.$BBOX_COMMA.osm.pbf")"
if [ "$PBF_FILE" -nt "$AFTER_FILENAME" ] ; then
	NEWFILE=$(mktemp -p . tmp.time2.XXXXXX.osm.pbf)
	echo "Extracting 'after' data..."
	osmium time-filter --overwrite -o "$NEWFILE" "$PBF_FILE" "$TIME_AFTER"
	mv "$NEWFILE" "$AFTER_FILENAME"
fi


if ! type "carto" >/dev/null ; then
	npm install carto -q
fi
if [ ! -s "$ROOT/openstreetmap-carto/project.xml" ] ; then
	cd "$ROOT"
	git submodule add https://github.com/gravitystorm/openstreetmap-carto.git
	cd "$ROOT/openstreetmap-carto"
	if [ project.mml -nt project.xml ] ; then
		./node_modules/.bin/carto -a 3.0.0 project.mml > project.xml
	fi
	dropdb gis || true
	createdb gis
	psql -d gis -c "create extension postgis;"
	psql -d gis -c "create extension hstore;"
	./scripts/get-external-data.py -v
	cd "$ROOT"
fi

if [ "$BEFORE_FILENAME" -nt "$ROOT/.$PREFIX.$TIME_BEFORE.$BBOX_COMMA.generated" ] ; then
	cd "$ROOT/openstreetmap-carto"
	osm2pgsql -G --hstore --style openstreetmap-carto.style --tag-transform-script openstreetmap-carto.lua -d gis "$BEFORE_FILENAME"
	psql -d gis -f indexes.sql
	touch "$ROOT/.$PREFIX.$TIME_BEFORE.$BBOX_COMMA.generated"
fi

cd "$ROOT"

for ZOOM in $(seq "$MIN_ZOOM" "$MAX_ZOOM") ; do
	if [ "$ROOT/.$PREFIX.$TIME_BEFORE.$BBOX_COMMA.generated" -nt "$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png" ] ; then
		# eventually the image is too large, so then just break out of the loop
		echo "Generating zoom ${ZOOM} level"
		nik4 openstreetmap-carto/project.xml "$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png" -b $BBOX_SPACE -z "$ZOOM" || break
		NEW="$(mktemp tmp.XXXXXX.png)"
		gm convert "$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png" -background white label:"${TIME_BEFORE}" -gravity center -append "$NEW"
		mv "$NEW" "$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png"
		gm convert "$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png" -background white label:"Data © OpenStreetMap contributors, ODbL" -gravity center -append "$NEW"
		mv "$NEW" "$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png"
	fi
done

if [ "$AFTER_FILENAME" -nt "$ROOT/.$PREFIX.$TIME_AFTER.$BBOX_COMMA.generated" ] ; then
	cd "$ROOT/openstreetmap-carto"
	osm2pgsql -G --hstore --style openstreetmap-carto.style --tag-transform-script openstreetmap-carto.lua -d gis "$AFTER_FILENAME"
	psql -d gis -f indexes.sql
	touch "$ROOT/.$PREFIX.$TIME_AFTER.$BBOX_COMMA.generated"
fi

cd "$ROOT"
for ZOOM in $(seq "$MIN_ZOOM" "$MAX_ZOOM") ; do
	if [ "$ROOT/.$PREFIX.$TIME_AFTER.$BBOX_COMMA.generated" -nt "$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png" ] ; then
		# eventually the image is too large, so then just break out of the loop
		echo "Generating zoom ${ZOOM} level"
		nik4 openstreetmap-carto/project.xml "$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png" -b $BBOX_SPACE -z "$ZOOM" || break
		NEW="$(mktemp tmp.XXXXXX.png)"
		gm convert "$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png" -background white label:"$TIME_AFTER" -gravity center -append "$NEW"
		mv "$NEW" "$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png"
		gm convert "$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png" -background white label:"Data © OpenStreetMap contributors, ODbL" -gravity center -append "$NEW"
		mv "$NEW" "$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png"
	fi
done

cd "$ROOT"
for ZOOM in $(seq "$MIN_ZOOM" "$MAX_ZOOM") ; do
	NEW_PNG="progress.$PREFIX.$TIME_BEFORE.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png"
	BEFORE="$PREFIX.$TIME_BEFORE.$BBOX_COMMA.z${ZOOM}.png"
	AFTER="$PREFIX.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.png"
	if [ ! -s "$BEFORE" ] || [ ! -s "$AFTER" ] ; then
		continue
	fi
	echo "Generating comparison image for zoom $ZOOM"

	if [ "$BEFORE" -nt "$NEW_PNG" ] || [ "$AFTER" -nt "$NEW_PNG" ] ; then
		TMP="$(mktemp tmp.XXXXXX.png)"
		gm montage -geometry +0+0  "$BEFORE" "$AFTER" "$TMP"
		gm convert "$TMP" -background white label:"Data © OpenStreetMap contributors, ODbL" -gravity center -append "$NEW_PNG"
	fi

	if [ "$BEFORE" -nt "$NEW_PNG" ] || [ "$AFTER" -nt "$NEW_PNG" ] ; then
		gm montage -geometry +0+0  "$BEFORE" "$AFTER" "$NEW_PNG"
	fi

	NEW_GIF="progress.$PREFIX.$TIME_BEFORE.$TIME_AFTER.$BBOX_COMMA.z${ZOOM}.gif"
	if [ "$BEFORE" -nt "$NEW_GIF" ] || [ "$AFTER" -nt "$NEW_GIF" ] ; then
		gm convert -delay 50 "$BEFORE" "$AFTER" "$NEW_GIF"
	fi

done


