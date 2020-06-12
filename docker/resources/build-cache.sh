#!/bin/bash
set -e

HOST_ADDRESS="http://localhost:7200"

# Check for dependant env variables.
[ -z "${APP_HOME}" ] && echo "APP_HOME not set" && exit 1
[ -z "${GRAPHDB_HOME}" ] && echo "GRAPHDB_HOME not set" && exit 1
[ -z "${GRAPHDB_SOURCE}" ] && echo "GRAPHDB_SOURCE not set" && exit 1
[ -z "${REPO_CONFIG}" ] && echo "REPO_CONFIG not set" && exit 1
[ -z "${REPO_NAME}" ] && echo "REPO_NAME not set - using 'default'" && REPO_NAME="default"
[ -z "${PRELOAD_CHUNK_SIZE}" ] && echo "PRELOAD_CHUNK_SIZE not set - using 1m" && PRELOAD_CHUNK_SIZE=1m
[ -z "${PRELOAD_ITER_SIZE}" ] && echo "PRELOAD_ITER_SIZE not set - using 6400" && PRELOAD_ITER_SIZE=6400

SPARQL_ENDPOINT="$HOST_ADDRESS/repositories/$REPO_NAME"
STATEMENTS_ENDPOINT="$SPARQL_ENDPOINT/statements"

env

echo "GDB_HEAP_SIZE set at ${GDB_HEAP_SIZE}"

if [ -n "${FORCE_REFRESH}" ]; then
    echo "Downloading the Data"
    cd ${GRAPHDB_SOURCE}
    if [ -z "${SKIP_DOWNLOAD}" ]; then
       #clear out the old stuff
       echo "Wiping the directory of files at: ${GRAPHDB_SOURCE}"
       rm -rf ${GRAPHDB_SOURCE}/*
    fi

    start_time=`date +%s`
    #Download all relevant data
    #Skip if SKIP_DOWNLOAD is set - assumes data is in ${GRAPHDB_SOURCE}
    if [ -z "${SKIP_DOWNLOAD}" ]; then
       echo "Downloading data via ${APP_HOME}/download-data.sh"
       #download-data.sh must exist here!
       ${APP_HOME}/download-data.sh    
    fi
    download_time=`date +%s`

    #Load all the data into the database (force replace)
    echo "Loading data via ${GRAPHDB_HOME}/bin/loadrdf --force -m parallel -p -v -c ${REPO_CONFIG} ${GRAPHDB_SOURCE}"
    ${GRAPHDB_HOME}/bin/loadrdf --force -m parallel -p -v -c ${REPO_CONFIG} ${GRAPHDB_SOURCE}
    #echo "\nPreloading data via ${GRAPHDB_HOME}/bin/preload --force -p --chunk ${PRELOAD_CHUNK_SIZE} --iter.cache ${PRELOAD_ITER_SIZE} -c ${REPO_CONFIG} ${GRAPHDB_SOURCE}"
    #${GRAPHDB_HOME}/bin/preload --force -p --chunk ${PRELOAD_CHUNK_SIZE} --iter.cache=${PRELOAD_ITER_SIZE} -c ${REPO_CONFIG} ${GRAPHDB_SOURCE}
    load_time=`date +%s`

    #start the db in the background
    ${GRAPHDB_HOME}/bin/graphdb & 
    GRAPHDB_PID=$!

    #wait for it to startup
    echo "Waiting for GraphDB to start up"
    until $(curl --output /dev/null --silent --head --fail http://localhost:7200); do
        printf '.'
        sleep 2
    done
    echo "GraphDB started"
    startup_time=`date +%s`

    #Loop precondition file and send to graphql
    #Might be worth looking to use parallel or xargs to run these in parallel, graphdb appear to be only using
    # 1cpu per request. AWS box has 4. Something like:
    # xargs -n1 -P4 bash -c 'i=$0; url="http://example.com/?page${i}.html"; curl -O -s $url'
    scripts=(${APP_HOME}/pre-condition-files/*.sparql)    

    for i in ${!scripts[*]}; do
        filename=${scripts[$i]}
        echo "Pre-condition Script: $filename"
        curl -X POST ${STATEMENTS_ENDPOINT} -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/sparql-results+json" --data-urlencode "update@$filename"
        script_times[$i]=`date +%s`
    done

    #sleep for a bit, just to make sure last command has flushed
    sleep 30

    #This is the suggest method from graphdb to stop the container
    kill ${GRAPHDB_PID}

    #Metrics
    #Sleep just to put metrics at the end after kill
    sleep 20
    finish_time=`date +%s`
    echo "" 
    echo "======================================================="
    echo "  Build Metrics (minutes)"
    echo "======================================================="
    echo "Download Data: $((($download_time-$start_time)/60))"
    echo "Graph DB Load Data: $((($load_time-$download_time)/60))"
    echo "Graph DB Startup: $((($startup_time-$load_time)/60))"
    prev_time=$startup_time
    for i in ${!scripts[*]}; do
        filename=${scripts[$i]}
        script_time=${script_times[$i]}
        echo "Pre-condition ($filename): $((($script_time-$prev_time)/60))"
        prev_time=$script_time
    done
    echo "Total Time: $((($finish_time-$start_time)/60))"

else
    #Just start of the GraphDB instance
    echo "Starting GraphsDB with existing data: no building"
    ${GRAPHDB_HOME}/bin/graphdb
fi

