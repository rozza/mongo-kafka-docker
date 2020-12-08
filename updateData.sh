#!/bin/bash

docker-compose exec mongo1 /usr/bin/mongo --eval '
db = db.getSiblingDB("test");
for (i = 0; i < 1000; i++) {
    db.investigate1.updateOne({ "_id": 535054140835066 }, { "$set": { "updateId": "update_" + i } });
}
'
