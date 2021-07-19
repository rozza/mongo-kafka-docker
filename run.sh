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

echo -e "\nKafka Connector Plugins:"
curl -X GET "http://localhost:8083/connector-plugins/" -w "\n"


echo -e "\nKafka Connectors:"
curl -X GET "http://localhost:8083/connectors/" -w "\n"


echo -e '''

==============================================================================================================
Examine the topics in the Kafka UI: http://localhost:9021

Examine the collections:
  - In your shell run: docker-compose exec mongo1 /usr/bin/mongo

Manually install a connector:
-----------------------------
docker-compose exec connect confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.5.0/
or 
docker-compose exec connect confluent-hub install --no-prompt /usr/share/confluent-plugins/mongodb-kafka-connect-mongodb-1.7.0-SNAPSHOT.zip

then:
docker-compose restart connect

 ============================================================================================================

Rest API: https://docs.confluent.io/current/connect/references/restapi.html

Examples: 
List connectors: curl -X GET http://localhost:8083/connectors
Add a connector: curl -X POST -H "Content-Type: application/json" -d @mongoSourceConfig.json  http://localhost:8083/connectors
Reconfigure a connector: curl -X PUT -H "Content-Type: application/json" -d @mongoSourceConfigAlt.json  http://localhost:8083/connectors
Restart a connector: curl -X POST http://localhost:8083/connectors/mongo-connector-test/restart
Delete a connector: curl -X DELETE http://localhost:8083/connectors/mongo-connector-test


==============================================================================================================



Use <ctrl>-c to quit'''

read -r -d '' _ </dev/tty
