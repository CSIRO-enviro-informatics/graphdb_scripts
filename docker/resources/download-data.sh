#!/bin/sh
set -e

# Add wget commands like what's below
# wget "${ASGS_DATASET_BASE}/asgs2016_ced.nt.gz" 	
# wget "http://linked.data.gov.au/dataset/asgs2016/reg/?_view=reg&_format=text/turtle" -O asgs2016.reg.ttl
wget https://protege.stanford.edu/ontologies/pizza/pizza.owl -O pizza.owl

if ls *.html 1> /dev/null 2>&1; then
    echo "Likely and error in the downloads, check the URLs"
    exit 1
fi
