## How to add the validator to the cosmos-sdk based blockchain.

### 1. Initialize the blockchain.

```sh
$ docker-compose run peer0-init 
$ docker-compose up peer0

peer0_1       | 7:59AM INF commit synced commit=436F6D6D697449447B5B3137372030203135332034312031313920313736203130332031373620313837203231362032313020353120372032333120313539203233352034312031373020363320333620363120312032312035362032343220313332203831203235352031373020313239203130322038355D3A317D
peer0_1       | 7:59AM INF committed state app_hash=B100992977B067B0BBD8D23307E79FEB29AA3F243D011538F28451FFAA816655 height=1 module=state num_txs=0
peer0_1       | 7:59AM INF indexed block exents height=1 module=txindex
```

### 2. Add the peer1 and peer2
```sh
$ docker-compose run peer1-init
$ docker-compose run peer2-init

- address: cosmos15mketdru3gdpch70p0vgudmj9dr2cu22qxw38t
  name: peer1-validator
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"A12gAfDUvUWIqqYuZ82cpdJhh45xWSClEe7iw4mCDh14"}'
  type: local

**Important** write this mnemonic phrase in a safe place.
It is the only way to recover your account if you ever forget your password.

suspect face layer goat fancy orient cactus crew element shield disagree gown before gaze atom minor escape before fruit weekend onion keen school choose
```

The result of peer1 and peer2 initialization is
* All the peers use same `genesis.json`.
* Each node-id is added into the `persistent_peers` in `config.toml`.

### 3. Run all the peers
```sh
docker-compose up peer1
docker-compose up peer2
```

Now only peer0 is the validator'. 
The pee1 and the peer2 only can receive the blocks.

### 4. Send staking amount to pee1

```sh
# get the delegator address for peer1-validator  
$ PEER1_DELEGATOR_ADDRESS=$(docker-compose exec peer1 hellod keys show peer1-validator -a --keyring-backend test)

# remove line separator
# PEER1_DELEGATOR_ADDRES is like 'cosmos1j6racgqqkqgs8km7l9f7zx767ltyylgarthvdc'
$ PEER1_DELEGATOR_ADDRESS=${PEER1_DELEGATOR_ADDRESS/%?/}

# send the token to delegator address
$ docker-compose exec peer0 hellod tx bank send peer0-validator $PEER1_DELEGATOR_ADDRESS 15000000stake --keyring-backend test -y

# set the validator pubkey
# PEER1_VALIDATOR_PUBKEY is like '{"@type":"/cosmos.crypto.ed25519.PubKey","key":"qJKnTKMeFaxGoU5DQmXOnXybYIPTDLH0/n0g1QM5C2U="}'
$ PEER1_VALIDATOR_PUBKEY=$(docker-compose exec peer1 hellod tendermint show-validator)

# enable the peer1-validator 
$ docker-compose exec peer1 hellod tx staking create-validator --amount=12000000stake --pubkey=$PEER1_VALIDATOR_PUBKEY --moniker="peer1" --commission-rate="0.10" --commission-max-rate="0.20" --commission-max-change-rate="0.01" --min-self-delegation="1000"  --gas-prices="0.0025stake" --from=peer1-validator --keyring-backend=test -y 
```

### 5. Send staking amount to pee2
```sh
# get the delegator address for peer2-validator  
$ PEER2_DELEGATOR_ADDRESS=$(docker-compose exec peer2 hellod keys show peer2-validator -a --keyring-backend test)

# remove line separator
$ PEER2_DELEGATOR_ADDRESS=${PEER2_DELEGATOR_ADDRESS/%?/}

# send the token to delegator address
$ docker-compose exec peer0 hellod tx bank send peer0-validator $PEER2_DELEGATOR_ADDRESS 15000000stake --keyring-backend test -y

# set the validator pubkey
$ PEER2_VALIDATOR_PUBKEY=$(docker-compose exec peer2 hellod tendermint show-validator)

# enable the peer2-validator 
$ docker-compose exec peer2 hellod tx staking create-validator --amount=12000000stake --pubkey=$PEER2_VALIDATOR_PUBKEY --moniker="peer1" --commission-rate="0.10" --commission-max-rate="0.20" --commission-max-change-rate="0.01" --min-self-delegation="1000"  --gas-prices="0.0025stake" --from=peer2-validator --keyring-backend=test -y
```

### 6. Check the validator set
You can see 3 validators by following command if the transaction of `create-validator` is success .

```sh
$ docker-compose exec peer0 hellod query tendermint-validator-set

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

### 7. Restart peer1 and peer2
```sh
docker-compose stop peer1
docker-compose stop peer2
docker-compose up peer1
docker-compose up peer2
```

You can see `This node is a validator` in peer1's log and peer2's log

```
peer1_1       | 7:41AM INF This node is a validator addr=DCCDAA29C263580A16A0CA18342F666078E2B368 module=consensus pubKey=j60ySvfDuNCOBuN6br/Dzy8Y20skFaslYCKQJdLtGmI=
```

### 8. Receive the rewards

Check the rewards.
```sh
$ docker-compose exec peer1 hellod query distribution rewards $PEER1_DELEGATOR_ADDRESS

rewards:
- reward:
  - amount: "5206.965641711220000000"
    denom: stake
  validator_address: cosmosvaloper15mketdru3gdpch70p0vgudmj9dr2cu229j6ytc
total:
- amount: "5206.965641711220000000"
  denom: stake
```

Get the rewards.

```sh
$  docker-compose exec peer1 hellod tx distribution withdraw-all-rewards --from peer1-validator --keyring-backend test -y

# check result
$ docker-compose exec peer1 hellod query distribution rewards $PEER1_DELEGATOR_ADDRESS

docker-compose exec peer1 hellod query distribution rewards $PEER1_DELEGATOR_ADDRESS
rewards:
- reward:
  - amount: "121.118823529404000000"
    denom: stake
  validator_address: cosmosvaloper15mketdru3gdpch70p0vgudmj9dr2cu229j6ytc
total:
- amount: "121.118823529404000000"
  denom: stake
```

Get the rewards with commission.
```sh
$ docker-compose exec peer1 hellod tx distribution withdraw-rewards cosmosvaloper15mketdru3gdpch70p0vgudmj9dr2cu229j6ytc --commission --from peer1-validator --keyring-backend test -y

# check result
$ docker-compose exec peer1 hellod query distribution commission cosmosvaloper15mketdru3gdpch70p0vgudmj9dr2cu229j6ytc

commission:
- amount: "7.879973262032083892"
  denom: stake
```
