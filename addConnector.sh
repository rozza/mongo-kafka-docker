#!/bin/bash

curl -X POST -H "Content-Type: application/json" --data '
  {"name": "mongo-source-1",
   "config": {
        "connector.class":"com.mongodb.kafka.connect.MongoSourceConnector",
        "tasks.max":"1",  
        "connection.uri":"mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?readPreference=secondary&maxStalenessSeconds=300",
        "topic.prefix":"mongo",
        "database":"test",
        "collection":"investigate1",
        "change.stream.full.document": "updateLookup",
        "key.converter":"org.apache.kafka.connect.storage.StringConverter",  
        "key.converter.schemas.enable":"false",                                                                                                                                                                                                    
        "value.converter":"org.apache.kafka.connect.storage.StringConverter",                                                                                                                                                                                                
        "value.converter.schemas.enable":"false",
        "transforms.smttransform.dropfields": "eventGroups,source",
        "poll.max.batch.size": 100,
        "pipeline": "[ { $project: { \"updateDescription\":0 } } ]"
}}' http://localhost:8083/connectors;