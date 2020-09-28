#!/bin/bash

./network.sh down
docker volume rm $(docker volume ls -qf dangling="true")
cd docker
find . -type f -not -name '*docker-compose-ca.yaml' -not -name '*docker-compose-couch.yaml' -not -name '*docker-compose-test-net.yaml' | xargs rm
cd ..
rm ./conf.yaml
echo "10001" > './max-port'

