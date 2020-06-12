# GraphDB scripts

This repo provides a docker/docker-compose based approach to deploying a 
GraphDB instance. The Docker container that is deployed can be configured 
to download data (if needed), and pre-condition the graphDB store in case
custom SPARQL queries are required to be run after the data is loaded.


## Running commands
> ./startup.sh
On start, the container will check for the presence of files in the `GRAPHDB_SOURCE` directory. If found, it will assume data has been already loaded and simply start the database.
If no files are found, it will completely refresh the graph store with a remote download.

> ./startup.sh --local-build
Will force a refresh of the data based on what is in `cachedata` (without downloading), 
rebuild the cache, then startup the graph.

> ./startup.sh --rebuild
Will force a refresh of the data, rebuild the cache, then startup the graph.

> ./stop.sh
Will bring down the container

## Volumes
Its probably a good idea to create volumes for both the GraphDB backend, and `GRAPHDB_SOURCE` directory so the containers don't do a full reload everytime they start up.

-v /host/datadir:/app/cachedata
-v /host/graphdbdata:/graphdb/data

The compose file does this with named volumes
