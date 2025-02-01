FROM postgis/postgis:17-3.5 AS development_build

RUN apt-get update --quiet \
&& apt-get install --quiet -y --no-install-recommends \
 ca-certificates gnupg lsb-release locales \
 wget curl \
 git-core unzip \
 netcat \
&& locale-gen $LANG && update-locale LANG=$LANG


# Get packages
RUN apt-get update --quiet \
&& apt-get install --quiet -y --no-install-recommends \
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

RUN wget --quiet https://downloads.sourceforge.net/gs-fonts/ghostscript-fonts-std-8.11.tar.gz \
&& tar xf ghostscript-fonts-std-8.11.tar.gz \
&& mkdir -p /usr/share/fonts/type1/ \
&& mv fonts/ /usr/share/fonts/type1/gsfonts

# Install python libraries

RUN pip install pyyaml nik4 requests notebook jupyterlab ipywidgets

# Install carto for stylesheet
RUN npm install -g carto@1.2.0

ENV HOME=/home/postgres

# Make sure the contents of our repo are in ${HOME}
COPY . ${HOME}
RUN usermod -u 1000 postgres
RUN chown -R 1000 ${HOME}
USER postgres

RUN mkdir -p ${HOME}/openstreetmap-carto/data
RUN mkdir -p ${HOME}/output
RUN mkdir -p ${HOME}/pgdata
WORKDIR ${HOME}

RUN git clone https://github.com/geofabrik/sendfile_osm_oauth_protector

ENTRYPOINT ["./entrypoint-new.sh"]
