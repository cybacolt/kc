# kc
Kafka Connect CLI

This is a CLI wrapper for the Kafka Connector API. While its assumed you are using the Confluent container, the script can be configured to use a custom endpoint.

## Requirements
- curl
- jq
- docker
- awk

## Setup

If using the Confluent container (cp-kafka-connect), the API endpoint will be automatically discovered.

Otherwise, the following environment variables can be set:
...


## Usage
```
kc connectors | logging | help
kc plugins { <plugin> validate plugin-config.json }
kc <connector> { delete
                 pause
                 resume
                 restart
                 topics
                 topics reset
                 tasks
                 tasks <num>
                 tasks <num> status | restart
                 config
                 config config-file.json }
kc logging { ERROR | WARN | INFO | DEBUG | TRACE }
```