## How to send the token to other chain with IBC.

### 1. Build chain-a and chain-b
```sh
docker build -t chaina -f Dockerfile.chaina .
docker build -t chainb -f Dockerfile.chainb .
```

### 2. Initialize each chains.

```sh
docker-compose run chainA-init
docker-compose run chainB-init
```

### 3. Run each chains.

```sh
docker-compose up chainA
docker-compose up chainB
```

### 4. Create relayer account.
```sh
# source account
docker-compose run relayer-account-ab
# target account
docker-compose run relayer-account-ba
```

### 5. Initialize the relayer.

Input relayer options.
```sh
$ docker-compose run relayer-init

Creating ibc_relayer-init_run ... done
------
Setting up chains
------

? Source Faucet (optional)
? Target Faucet (optional)
? Source Gas Limit 300000
? Target Gas Limit 300000
? Source Address Prefix cosmos
? Target Address Prefix cosmos

🔐  Account on "source" is relayer-a-b(cosmos13e9dahsw6jvs8yppfa34wffq0924gsdpz7ttx4)

 |· no faucet available, please send coins to the address
 |· (balance: -)

🔐  Account on "target" is relayer-b-a(cosmos1tqull2cfaa0h4t39p85a2su00u9402yezzfa09)

 |· no faucet available, please send coins to the address
 |· (balance: -)

⛓  Configured chains: chaina-chainb
```

### 6. Send base tokens to relayer account

Send `basea` from chaina-validator to source account
```sh
docker-compose exec chainA chainad tx bank send chaina-validator cosmos13e9dahsw6jvs8yppfa34wffq0924gsdpz7ttx4 1000000basea --keyring-backend test -y
```

Send `baseb` from chainb-validator to target account.

```sh
docker-compose exec chainB chainbd tx bank send chainb-validator cosmos1tqull2cfaa0h4t39p85a2su00u9402yezzfa09 1000000baseb --keyring-backend test -y
```

### 7. Check the balance of each relayer account

```sh
$ docker-compose exec chainA chainad query bank balances cosmos13e9dahsw6jvs8yppfa34wffq0924gsdpz7ttx4

balances:
- amount: "1000000"
  denom: basea
pagination:
  next_key: null
  total: "0"
```

```sh
$ docker-compose exec chainB chainbd query bank balances cosmos1tqull2cfaa0h4t39p85a2su00u9402yezzfa09

balances:
- amount: "1000000"
  denom: baseb
pagination:
  next_key: null
  total: "0"
```

### 8. Run the relayer.

It will take a few minutes.
```
$ docker-compose up relayer

Starting ibc_relayer_1 ... done
Attaching to ibc_relayer_1
relayer_1             | ------
relayer_1             | Paths
relayer_1             | ------
relayer_1             |
relayer_1             | chaina-chainb:
relayer_1             |     chaina > (port: transfer) (channel: channel-0)
relayer_1             |     chainb > (port: transfer) (channel: channel-0)
relayer_1             |
relayer_1             | ------
relayer_1             | Listening and relaying packets between chains...
relayer_1             | ------
relayer_1             |
```

### 9. Send 'coin' token from chainA to chainB

```
CHAINB_ACCOUNT=$(docker-compose exec chainB chainbd keys show chainb-validator -a --keyring-backend test)
CHAINB_ACCOUNT=${CHAINB_ACCOUNT/%?/}
docker-compose exec chainA chainad tx ibc-transfer transfer transfer channel-0 $CHAINB_ACCOUNT 100coin --from chaina-validator --keyring-backend test -y
```

You can see syn and ack message in relayer log.
```
relayer_1             | Relay 1 packets from chaina => chainb
relayer_1             | Relay 1 acks from chainb => chaina
```

Then chainb account have 100 token named (ibc/XXXX).  
chainB's `coin` denom is different from chainA's `coin` denom.  
chainA's `coin` denom is `ibc/E28E3061A3D182C001E9A68486881E4EED7E8D23FC7B02002D3BEAABCCC226F2` in chainB.

```
$ docker-compose exec chainB chainbd query bank balances $CHAINB_ACCOUNT

balances:
- amount: "9989000000"
  denom: baseb
- amount: "10000"
  denom: coin
- amount: "100"
  denom: ibc/E28E3061A3D182C001E9A68486881E4EED7E8D23FC7B02002D3BEAABCCC226F2
pagination:
  next_key: null
  total: "0"
```

### 9. Send 'ibc/xx' token from chainB to chainA
```sh
CHAINA_ACCOUNT=$(docker-compose exec chainA chainad keys show chaina-validator -a --keyring-backend test)
CHAINA_ACCOUNT=${CHAINA_ACCOUNT/%?/}
docker-compose exec chainB chainbd tx ibc-transfer transfer transfer channel-0 $CHAINA_ACCOUNT 10ibc/E28E3061A3D182C001E9A68486881E4EED7E8D23FC7B02002D3BEAABCCC226F2 --from chainb-validator --keyring-backend test -y
```

The chainA's `coin become 9910 (1000 - 100 + 10).

```sh
$ docker-compose exec chainA chainad query bank balances $CHAINA_ACCOUNT

balances:
- amount: "9989000000"
  denom: basea
- amount: "9910"
  denom: coin
pagination:
  next_key: null
  total: "0"
```
