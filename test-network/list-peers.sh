#!/bin/bash
# first save the discovery config

userKey=$(find /Users/shuyizhang/Documents/code/fabric-2.2/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/ -name "*_sk")
echo "userKey=$userKey"

discover --configFile conf.yaml --peerTLSCA /Users/shuyizhang/Documents/code/fabric-2.2/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/tls-localhost-7054-ca-org1.pem --userKey ${userKey} --userCert /Users/shuyizhang/Documents/code/fabric-2.2/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/cert.pem  --MSP Org1MSP saveConfig
discover --configFile conf.yaml peers --channel mychannel  --server localhost:7051

