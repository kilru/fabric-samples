./network.sh down
docker volume rm $(docker volume ls -qf dangling="true")
cd docker
rm -v !("docker-compose-ca.yaml"|"docker-compose-couch.yaml"|"docker-compose-test-net.yaml") 
echo "10001" > './max-port'

