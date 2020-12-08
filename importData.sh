#!/bin/bash

docker exec -i mongo1 sh -c 'mongoimport -c investigate1 -d test' < sample_data.json