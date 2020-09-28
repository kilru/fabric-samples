while getopts p:o:c:r: flag
do
    case "${flag}" in
        p) peerName=${OPTARG};;
        o) orgName=${OPTARG};;
        c) caPort=${OPTARG};;
        r) corePeerPort=${OPTARG};;
    esac
done
echo "peerName: $peerName";
echo "orgName: $orgName";
echo "caPort: $caPort";
echo "corePeerPort: $corePeerPort";
capOrgName="$(tr '[:lower:]' '[:upper:]' <<< ${orgName:0:1})${orgName:1}"

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="${capOrgName}MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/peer0.${orgName}.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${orgName}.example.com/users/Admin@${orgName}.example.com/msp
export CORE_PEER_ADDRESS=localhost:${corePeerPort}
export PATH=$PATH:$PWD/../bin/
export FABRIC_CFG_PATH=$PWD/../config/
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${orgName}.example.com/

fabric-ca-client register --caname ca-${orgName} --id.name ${peerName} --id.secret ${peerName}pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/${orgName}/tls-cert.pem
mkdir -p organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com
fabric-ca-client enroll -u https://${peerName}:${peerName}pw@localhost:${caPort} --caname ca-${orgName} -M ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/msp --csr.hosts ${peerName}.${orgName}.example.com --tls.certfiles ${PWD}/organizations/fabric-ca/${orgName}/tls-cert.pem
cp ${PWD}/organizations/peerOrganizations/${orgName}.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/msp/config.yaml
fabric-ca-client enroll -u https://${peerName}:${peerName}pw@localhost:${caPort} --caname ca-${orgName} -M ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls --enrollment.profile tls --csr.hosts ${peerName}.${orgName}.example.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/${orgName}/tls-cert.pem
cp ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls/ca.crt
cp ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls/server.crt
cp ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls/server.key

read -r portOne<'./max-port'
echo "portOne=${portOne}"
portTwo=$((portOne+1))
echo "portTwo=${portTwo}"
nextPort=$((portOne+10))

cat << EOF > ./docker/docker-compose-${peerName}-${orgName}.yaml
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

version: '2'

volumes:
  ${peerName}.${orgName}.example.com:

networks:
  test:

services:

  ${peerName}.${orgName}.example.com:
    container_name: ${peerName}.${orgName}.example.com
    image: hyperledger/fabric-peer:\$IMAGE_TAG
    environment:
      #Generic peer variables
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      # the following setting starts chaincode containers on the same
      # bridge network as the peers
      # https://docs.docker.com/compose/networking/
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=\${COMPOSE_PROJECT_NAME}_test
      - FABRIC_LOGGING_SPEC=INFO
      #- FABRIC_LOGGING_SPEC=DEBUG
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_PROFILE_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      # Peer specific variabes
      - CORE_PEER_ID=${peerName}.${orgName}.example.com
      - CORE_PEER_ADDRESS=${peerName}.${orgName}.example.com:${portOne}
      - CORE_PEER_LISTENADDRESS=0.0.0.0:${portOne}
      - CORE_PEER_CHAINCODEADDRESS=${peerName}.${orgName}.example.com:${portTwo}
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:${portTwo}
      - CORE_PEER_GOSSIP_BOOTSTRAP=${peerName}.${orgName}.example.com:${portOne}
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=${peerName}.${orgName}.example.com:${portOne}
      - CORE_PEER_LOCALMSPID=${capOrgName}MSP
    volumes:
        - /var/run/:/host/var/run/
        - ../organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/msp:/etc/hyperledger/fabric/msp
        - ../organizations/peerOrganizations/${orgName}.example.com/peers/${peerName}.${orgName}.example.com/tls:/etc/hyperledger/fabric/tls
        - ${peerName}.${orgName}.example.com:/var/hyperledger/production
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    ports:
      - ${portOne}:${portOne}
    networks:
      - test
EOF

docker-compose -f ./docker/docker-compose-${peerName}-${orgName}.yaml up -d
CORE_PEER_ADDRESS=localhost:${portOne} peer channel join -b channel-artifacts/mychannel.block
echo $nextPort > './max-port'
