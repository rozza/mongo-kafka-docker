# MongoDB & Kafka Docker setup

Test using the mongodb kafka connector

## Requirements
  - Docker 18.09+
  - Docker compose 1.24+
  - *nix system

## Running the example

To run the example: `./run.sh` which will:
  
  - Run `docker-compose up` 
  - Wait for MongoDB, Kafka, Kafka Connect to be ready

Once running, examine the topics in the Kafka control center: http://localhost:9021/


Examine the collections in MongoDB:
  - In your shell run: docker-compose exec mongo1 /usr/bin/mongo

## docker-compose.yml

The following systems will be created:

  - Zookeeper
  - Kafka
  - Confluent Schema Registry
  - Confluent Kafka Connect
  - Confluent Control Center
  - Confluent KSQL Server
  - Kafka Rest Proxy
  - MongoDB - a 3 node replicaset


## Adding connectors

### Install Mongo Connector:

```
docker-compose exec connect confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.3.0/
docker-compose restart connect
```

Alternatively, add any connectors to the plugins directory before starting (if testing a snapshot)


## Configure Kafka connect via the rest API


| **ACTION**      | **COMMAND** |
| :-------------- | :---------- |
| List plugins    | curl -X GET http://localhost:8083/connector-plugins |
| List connectors | curl -X GET http://localhost:8083/connectors |
| Add connector   | curl -X POST -H "Content-Type: application/json" -d @config1.json  http://localhost:8083/connectors |
| Reconfigure     | curl -X PUT -H "Content-Type: application/json" -d @config2.json  http://localhost:8083/connectors |

Full API reference: https://docs.confluent.io/current/connect/references/restapi.html

---

[Mongo Kafka Connector Usage guide](https://docs.mongodb.com/kafka-connector/current/)
