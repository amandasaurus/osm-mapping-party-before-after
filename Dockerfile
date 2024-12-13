FROM postgis/postgis:15-3.5 AS development_build

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 ca-certificates gnupg lsb-release locales \
 wget curl \
 git-core unzip \
&& locale-gen $LANG && update-locale LANG=$LANG 


# Get packages
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 make \
 fonts-hanazono \
 fonts-noto-cjk \
 fonts-noto-hinted \
 fonts-noto-unhinted \
 fonts-unifont \
 gdal-bin \
 graphicsmagick \
 liblua5.3-dev \
 libosmium2-dev \
 libprotozero-dev \
 lua5.3 \
 mapnik-utils \
 npm \
 osm2pgsql \
 osmium-tool \
 osmosis \
 python-is-python3 \
 python3-mapnik \
 python3-lxml \
 python3-psycopg2 \
 python3-shapely \
 python3-pip \
 sudo \
 vim \
&& apt-get clean autoclean \
&& apt-get autoremove --yes \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN wget https://downloads.sourceforge.net/gs-fonts/ghostscript-fonts-std-8.11.tar.gz
RUN tar xvf ghostscript-fonts-std-8.11.tar.gz
RUN mkdir -p /usr/share/fonts/type1/
RUN mv fonts/ /usr/share/fonts/type1/gsfonts

# Install python libraries

RUN pip install pyyaml nik4 requests

# Install carto for stylesheet
RUN npm install -g carto@1.2.0


COPY . /workdir

RUN mkdir -p /workdir/openstreetmap-carto/data 
RUN mkdir -p /workdir/output

WORKDIR /workdir

RUN chown postgres:postgres -R /workdir  

USER postgres
