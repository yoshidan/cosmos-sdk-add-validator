## How to add the validator to the cosmos-sdk based blockchain.

### Build the blockchain application.

```
git clone https://github.com/yoshidan/cosmos-sdk-add-validator
cd cosmos-sdk-add-validator
docker build -t hellod .
```

### Initialize the blockchain and run peer0.

```
docker-compose run peer0-init 
docker-compose up peer0
```

The peer0 successfully launch.

```
peer0_1       | 7:59AM INF commit synced commit=436F6D6D697449447B5B3137372030203135332034312031313920313736203130332031373620313837203231362032313020353120372032333120313539203233352034312031373020363320333620363120312032312035362032343220313332203831203235352031373020313239203130322038355D3A317D
peer0_1       | 7:59AM INF committed state app_hash=B100992977B067B0BBD8D23307E79FEB29AA3F243D011538F28451FFAA816655 height=1 module=state num_txs=0
peer0_1       | 7:59AM INF indexed block exents height=1 module=txindex
```

### Add the peer1 and peer2
```
docker-compose run peer1-init
docker-compose run peer2-init
```

You can see validator address in the log.
```
- address: cosmos1wyx74cnm4pkl7lgpwjvcert9xgc2pk0kejmdrn
  name: peer2-validator
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"At22Mo8HkSaOjRzPfpQrG9y/q9rDISW0vnIwoTwRr6+2"}'
  type: local


**Important** write this mnemonic phrase in a safe place.
It is the only way to recover your account if you ever forget your password.

develop hedgehog side sort beauty kick animal undo double shallow frown betray axis leave empty suspect profit loud poverty dutch person fork regular alter
```

* All the peers use same `genesis.json`.
* Each node-id is added into the `persistent_peers` in config.toml.

### Run all the peers
```
docker-compose up peer1
docker-compose up peer2
```

Now only peer0 is the validator because peer1 and peer2 doesn't have account'. 
The pee1 and the peer2 only can receive the blocks.

### Send staking amount to pee1

```
# get the self-delegator address
PEER1_DELEGATOR_ADDRESS=$(docker-compose exec peer1 hellod keys show peer1-validator -a --keyring-backend test)

# remove line separator
PEER1_DELEGATOR_ADDRESS=${PEER1_DELEGATOR_ADDRESS/%?/}

# send the token to self-delegator-address
docker-compose exec peer0 hellod tx bank send peer0-validator $PEER1_DELEGATOR_ADDRESS 15000000stake --keyring-backend test

# set the validator pubkey
PEER1_VALIDATOR_PUBKEY=$(docker-compose exec peer1 hellod tendermint show-validator)

# create the peer1 validator 
docker-compose exec peer1 hellod tx staking create-validator --amount=12000000stake --pubkey=$PEER1_VALIDATOR_PUBKEY --moniker="peer1" --commission-rate="0.10" --commission-max-rate="0.20" --commission-max-change-rate="0.01" --min-self-delegation="1000"  --gas-prices="0.0025stake" --from=peer1-validator --keyring-backend=test
```

### Send staking amount to pee2
```
# get the self-delegator address
PEER2_DELEGATOR_ADDRESS=$(docker-compose exec peer2 hellod keys show peer2-validator -a --keyring-backend test)

# remove line separator
PEER2_DELEGATOR_ADDRESS=${PEER2_DELEGATOR_ADDRESS/%?/}

# send the token to self-delegator-address
docker-compose exec peer0 hellod tx bank send peer0-validator $PEER2_DELEGATOR_ADDRESS 15000000stake --keyring-backend test

# set the validator pubkey
PEER2_VALIDATOR_PUBKEY=$(docker-compose exec peer2 hellod tendermint show-validator)

# create the peer2 validator 
docker-compose exec peer2 hellod tx staking create-validator --amount=12000000stake --pubkey=$PEER2_VALIDATOR_PUBKEY --moniker="peer1" --commission-rate="0.10" --commission-max-rate="0.20" --commission-max-change-rate="0.01" --min-self-delegation="1000"  --gas-prices="0.0025stake" --from=peer2-validator --keyring-backend=test
```

### Check the validator set
You can see 3 validators by following command if the transaction of `create-validator` is success .

```
docker-compose exec peer0 hellod query tendermint-validator-set
```

```
block_height: "548"
total: "3"
validators:
- address: cosmosvalcons1t8l8qvhe4l9rw556hscjp8qs7wvl0awws25pa9
  proposer_priority: "13"
  pub_key:
    type: tendermint/PubKeyEd25519
    value: 2RIDWhtoeKfQNIqwGXgohoFT+7dVJK9e2efaNEw9fX0=
  voting_power: "12"
- address: cosmosvalcons1mnx652wzvdvq594qegvrgtmxvpuw9vmgpcrpmg
  proposer_priority: "-7"
  pub_key:
    type: tendermint/PubKeyEd25519
    value: j60ySvfDuNCOBuN6br/Dzy8Y20skFaslYCKQJdLtGmI=
  voting_power: "12"
- address: cosmosvalcons17v94mwrenyt7h3w20xhwh9pqa5c0fl6kzuz9ll
  proposer_priority: "-5"
  pub_key:
    type: tendermint/PubKeyEd25519
    value: 1GhpA+qPrUvQvmo/RU4rGYku/M++sSSFk12Ij590kHE=
  voting_power: "10"
```

The total voting_power is `34`( 2/3 is 22.6666666667).
* When only the peer0 is down, the `voting_power` is 24( > 22.6666666667), so this chain can mine the blocks.
* When only the peer1 is down, the `voting_power` is 22( < 22.6666666667), so this chain can't mine the block.

### Restart peer1 and peer2
```
docker-compose stop peer1
docker-compose stop peer2
docker-compose up peer1
docker-compose up peer2
```

You can see `This node is a validator` in peer1's log and peer2's log

```
peer1_1       | 7:41AM INF This node is a validator addr=DCCDAA29C263580A16A0CA18342F666078E2B368 module=consensus pubKey=j60ySvfDuNCOBuN6br/Dzy8Y20skFaslYCKQJdLtGmI=
```

