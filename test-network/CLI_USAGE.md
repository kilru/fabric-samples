# DFI fabric CLIs usage

## add-peer.sh

### Usage

```sh
/add-peer.sh -p ${peerName} -o ${orgName} -c ${caPort} -e ${corePeerPort}
```

### Setup

```sh
./network.sh up createChannel -ca
```

### Examples

Add peers to each org

```sh
./add-peer.sh -p peer1 -o org1 -c 7054 -e 7051 # add peer1 to org1
./add-peer.sh -p peer1 -o org2 -c 8054 -e 9051 # add peer1 to org2
```

List all peers

```sh
./list-peers.sh
```

### Tear Down

```sh
./cleanup.sh
```
