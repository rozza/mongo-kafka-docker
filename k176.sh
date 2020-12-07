#!/bin/bash

echo -e "\nInserting test documents into test.testCopyExisting\n"

function clean_up {
    echo -e "\n\nSHUTTING DOWN\n\n"
    docker-compose exec broker /usr/bin/kafka-topics --bootstrap-server broker:29092 --topic mongo.test.testCopyExisting --delete &> /dev/null
    curl -X DELETE http://localhost:8083/connectors/mongo-connector-test &> /dev/null
}

trap clean_up EXIT

docker-compose exec mongo1 /usr/bin/mongo --eval '''
db.getSiblingDB("test");
db.dropDatabase();

for (var i = 1; i <= 1000; i++) {
   db.testCopyExisting.insert( { x : i } );
}

db.testCopyExisting.count();
'''

sleep 2

echo -e "\nAdding connector to copy existing data from test.testCopyExisting\n"
curl -X POST -H "Content-Type: application/json" -d @config1.json  http://localhost:8083/connectors


echo -e '''

======================================================
Outputting data in topic `mongo.test.testCopyExisting`
======================================================

'''

docker-compose exec broker /usr/bin/kafka-console-consumer --bootstrap-server broker:29092 --topic mongo.test.testCopyExisting --from-beginning