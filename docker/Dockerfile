FROM ubuntu:18.04
MAINTAINER CSIRO Environmental Informatics "no-reply@csiro.au"

# Silence debconf messages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get -qq update && \
  apt-get -y install \
    byobu curl git htop man vim wget unzip \
    openjdk-8-jdk && \
  rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV APP_HOME='/app'
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
ENV GRAPHDB_HOME="/graphdb"
ENV GRAPHDB_ZIP="${APP_HOME}/graphdb.zip"
ENV REPO_CONFIG="${APP_HOME}/repo-config.ttl"
ENV GRAPHDB_SOURCE=${GRAPHDB_SOURCE:-"${APP_HOME}/cachedata"}
# Set GraphDB Max and Min Heap size (must be less than available RAM)
ENV GDB_HEAP_SIZE="${GDB_HEAP_SIZE:-1g}"
ENV PRELOAD_CHUNK_SIZE="${PRELOAD_CHUNK_SIZE:-1000}"
ENV PRELOAD_ITER_SIZE="${PRELOAD_ITER_SIZE:-500}"

WORKDIR ${APP_HOME}

RUN wget https://loci-assets.s3-ap-southeast-2.amazonaws.com/script-resources/graph-cache/graphdb-free-8.10.0-dist.zip -O ${GRAPHDB_ZIP}
# COPY ./graphdb-free-8.10.0-dist.zip ${GRAPHDB_ZIP}
RUN unzip ${GRAPHDB_ZIP} -d ${APP_HOME}/graphdb && \
    mv ${APP_HOME}/graphdb/graphdb-* ${GRAPHDB_HOME} && \
    rm ${GRAPHDB_ZIP}    

COPY resources/graphdb.properties ${GRAPHDB_HOME}/conf/graphdb.properties
COPY resources/repo-config.ttl ${REPO_CONFIG}
COPY resources/download-data.sh .
COPY resources/pre-condition-files/* pre-condition-files/

#Build the Cache
COPY resources/build-cache.sh ${APP_HOME}
WORKDIR ${APP_HOME}
EXPOSE 7200

CMD ["/bin/bash", "-c", "${APP_HOME}/build-cache.sh"]
