#!/bin/bash

set -e
(
if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null ; then
    echo "Please terminate the local mongod on 27017"
    exit 1
fi
)

echo "Starting docker ."
docker-compose up -d --build

function clean_up {
    echo -e "\n\nSHUTTING DOWN\n\n"
    docker-compose exec mongo1 /usr/bin/mongo --eval "db.dropDatabase()"
    docker-compose down
    if [ -z "$1" ]
    then
      echo -e "Bye!\n"
    else
      echo -e $1
    fi
}

sleep 5
echo -ne "\n\nWaiting for the systems to be ready.."
function test_systems_available {
  COUNTER=0
  until $(curl --output /dev/null --silent --head --fail http://localhost:$1); do
      printf '.'
      sleep 2
      let COUNTER+=1
      if [[ $COUNTER -gt 30 ]]; then
        MSG="\nWARNING: Could not reach configured kafka system on http://localhost:$1 \nNote: This script requires curl.\n"

          if [[ "$OSTYPE" == "darwin"* ]]; then
            MSG+="\nIf using OSX please try reconfiguring Docker and increasing RAM and CPU. Then restart and try again.\n\n"
          fi

        echo -e $MSG
        clean_up "$MSG"
        exit 1
      fi
  done
}

test_systems_available 8082
test_systems_available 8083

trap clean_up EXIT

echo -e "\nConfiguring the MongoDB ReplicaSet.\n"
docker-compose exec mongo1 /usr/bin/mongo --eval '''if (rs.status()["ok"] == 0) {
    rsconf = {
      _id : "rs0",
      members: [
        { _id : 0, host : "mongo1:27017", priority: 1.0 },
        { _id : 1, host : "mongo2:27017", priority: 0.5 },
        { _id : 2, host : "mongo3:27017", priority: 0.5 }
      ]
    };
    rs.initiate(rsconf);
}

rs.conf();'''

DEFAULT="Y"
read -r -p "Install latest MongoDB Connector?? [Y/n] " RESPONSE
RESPONSE=${RESPONSE:-${DEFAULT}}
if [[ "$RESPONSE" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    docker-compose exec connect confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:latest/
    docker-compose restart connect
fi

test_systems_available 8083



echo -e "\nKafka Topics:"
curl -X GET "http://localhost:8082/topics" -w "\n"

echo -e "\nKafka Connectors:"
curl -X GET "http://localhost:8083/connectors/" -w "\n"


echo -e '''

==============================================================================================================
Examine the topics in the Kafka UI: http://localhost:9021

Add the sink and the source:
curl -X POST -H "Content-Type: application/json" -d @sink.json  http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" -d @source.json  http://localhost:8083/connectors

Add docs to the "source" database: docker-compose exec mongo1 /usr/bin/mongo

They will show up in the "sink" database!


 ============================================================================================================
 ============================================================================================================

Rest API: https://docs.confluent.io/current/connect/references/restapi.html

Examples: 
List connectors: curl -X GET http://localhost:8083/connectors
Add a connector: curl -X POST -H "Content-Type: application/json" -d @config1.json  http://localhost:8083/connectors
Reconfigure a connector: curl -X PUT -H "Content-Type: application/json" -d @config2.json  http://localhost:8083/connectors
Delete a connector: curl -X DELETE http://localhost:8083/connectors/mongo-connector-test

==============================================================================================================


Use <ctrl>-c to quit'''

read -r -d '' _ </dev/tty
