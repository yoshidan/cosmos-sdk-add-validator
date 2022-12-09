## How to recovery the validator

### 1. Initialize the blockchain and run the validator node.

```sh
docker-compose run peer0-init 
docker-compose up peer0
```

### 2. Add the not validator node
```sh
docker-compose run peer1-init
docker-compose up peer1
```

* The peer1 uses same `genesis.json` as peer0.
* The peer0's node-id is added into the `persistent_peers` in peer1's `config.toml`.
* The peer1 start to receive the blocks from peer0.

### 3. Create test account and send token 

```sh
docker-compose exec peer0 hellod keys add test --keyring-backend test
```

Here is the log.
```
- address: cosmos12p098sgqwfhnw3gmssddl5kun54007vw99ak8n
  name: test
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"ArXVmEZIrLpMSi8IyUoZYmnYFrCLwpi2fZ4TvIPidfkH"}'
  type: local


**Important** write this mnemonic phrase in a safe place.
It is the only way to recover your account if you ever forget your password.
```

```sh
docker-compose exec peer0 hellod tx bank send peer0-validator cosmos12p098sgqwfhnw3gmssddl5kun54007vw99ak8n 10coin --keyring-backend test
docker-compose exec peer0 hellod query bank balances cosmos12p098sgqwfhnw3gmssddl5kun54007vw99ak8n
```

Here is query result.
```
balances:
- amount: "10"
  denom: coin
pagination:
  next_key: null
  total: "0"
```

### 4. Stop peer0 (emulate peer0 down)
```sh
docker-compose stop peer0
```

### 5. Create new node which use same config and validator as peer0

```sh
docker-compose run peer2-init
```

* The peer2's `config` and `keyring-test` directory is same as peer0's.
* The peer1's node-id is added into the `persistent_peers` in peer2's `config.toml`.

### 6. Run the restored node

```sh
docker-compose up peer2
```

Peer2 start to receive all the blocks from `peer1' and mine the blocks. 


### 7. Check the balance of the test account's token

```sh
docker-compose exec peer2 hellod query bank balances cosmos12p098sgqwfhnw3gmssddl5kun54007vw99ak8n
```

Here is the query result.
```
balances:
- amount: "10"
  denom: coin
pagination:
  next_key: null
  total: "0"
```
