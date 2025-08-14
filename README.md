# Devnet
Modified from: https://github.com/stacks-sbtc/sbtc/tree/v1.0.2/docker, changes:

- Deleted services related to sBTC, mempool and grafana
- Added 5 stacks miners, by default there are 3 miners competing for mining
- bind-mounts a local filesystem for data persistence

## Quickstart

### Start network in Epoch 3.2
Creates a dynamic chainstate folder at `./docker/chainstate/$(date +%s)`
```sh
make up
```
**note**: block production will resume after 2 Bitcoin blocks (timed to ~10s)

### Start network from genesis
Creates a static chainstate folder at `./docker/chainstate/genesis`
```sh
make up-genesis
```

### Stop the network
*note*: `down-genesis` target calls `down`
```sh
make down
```

### Logs
`docker logs -f <service>` will work, along with some defined Makefile targets

**Important:** Logs persist through reboots but are lost when the network is stopped. Perform these operations before running `make down` to preserve log data.

#### Store logs from all services under the current chainstate folder
```sh
make backup-logs
```

#### Stream logs from all services
```sh
make log-all
```
#### Stream single service logs
```sh
make log stacks-signer-1 -- -f
```

#### Log from a single service
*note* this will not follow the logs
```sh
make log stacks-signer-1
```

## Containers

- **bitcoin**: Runs a bitcoin regtest node
- **bitcoin-miner**: creates 5 bitcoin regtest wallets and mines regtest blocks at a configurable cadence
- **stacks-miner-1**: mines stacks blocks and sends events to stacks-signer-1
- **stacks-miner-2**: mines stacks blocks and sends events to stacks-signer-2
- **stacks-miner-3**: mines stacks blocks and sends events to stacks-signer-3
- **stacks-signer-1**: event observer for stacks-miner-1
- **stacks-signer-2**: event observer for stacks-miner-2
- **stacks-signer-3**: event observer for stacks-miner-3
- **stacker**: stack for `stacks-signer-1`, `stacks-signer-2` and `stacks-signer-3`
- **tx-broadcaster**: submits token transfer txs to ensure stacks block production during a sortition
- **monitor**: monitors block details and tracks stacking calls

## Stacks Miner Accounts

### Miner 1

```text
‣ Mnemonic:               arena glide gate doll group blood essence library clay scissors snow local gospel brass cup craft crop snow fiber rough way cattle equip topic
‣ Private Key:            9e446f6b0c6a96cf2190e54bcd5a8569c3e386f091605499464389b8d4e0bfc201
‣ Public Key:             035379aa40c02890d253cfa577964116eb5295570ae9f7287cbae5f2585f5b2c7c
‣ BTC Address:            miEJtNKa3ASpA19v5ZhvbKTEieYjLpzCYT
‣ Stacks Address:         STEW4ZNT093ZHK4NEQKX8QJGM2Y7WWJ2FQQS5C19
‣ WIF:                    cStMQXkK5yTFGP3KbNXYQ3sJf2qwQiKrZwR9QJnksp32eKzef1za
‣ Miner Reward Recipient: STQM73RQC4EX0A07KWG1J5ECZJYBZS4SJ4ERC6WN
  ‣ Private Key:          41aea3f0b909ab2427268e495b5238c77c04413eb75c6a2f9117b2d1e897c8f301
```

### Miner 2

```text
‣ Mnemonic:               cherry lawn pull huge drift wisdom capable bulk tragic street first foam onion above come smart eyebrow about soon jungle select used front ecology
‣ Private Key:            1415e80bf3fe30fe95889c676681b4f64447f8888f718381840224b14ef4b97801
‣ Public Key:             03a1940aedd43c39a39c73a1686faaabc67b6bd918d9710292e6c400308df0130e
‣ BTC Address:            mxxRn3xP98tSJCUXxABq4dgg4SziNacF1Y
‣ Stacks Address:         ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55
‣ WIF:                    cNFkBfqr4tz3V7pcKbBvcibKsZ6XnTmcTwyWoqGm4CStmqN1bqh8
‣ Miner Reward Recipient: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55
  ‣ Private Key:          c9f739fb35b00b78596b4ba4656ce143f95f1d9730a40309c9866470a4a7069f01
```

### Miner 3

```text
‣ Mnemonic:               identify test gallery pave now pet just gospel erupt walnut demand oyster old trigger soup zoo sheriff oyster twenty tragic license casual twelve depth
‣ Private Key:            c1c3f3f7bb8cc0b64c3be0f79488a3b1e3dbca62f23a5ac84e13beba78cc961301
‣ Public Key:             025511871cb065df0ac108d149b5abe2267242745fd02b1d7a5fafb8dcf3ad66ce
‣ BTC Address:            miBGjFEQveJSbzFwB9XJ9a4GmkY3Unmb7b
‣ Stacks Address:         STEJYWJ2Y7E72AF9JMRWZWNR11ADBJBHD45P7D7K
‣ WIF:                    cU5McyYQu1VJw6tzekyAJd1Jm9NVtjkPhrcbyVm8LgGdiW1Htrf4
‣ Miner Reward Recipient: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55
  ‣ Private Key:          357e5e4bb609bd9e811a4105384926ddfbd755f30c18649fe405c7c57c55b58601
```

### Miner 4

```text
‣ Mnemonic:               report weasel jealous pizza long order section oak dignity radar combine project broom glass bridge pulp glory magic dutch toe undo patient photo core
‣ Private Key:            2eafe91d1bf9a37a650717f208d16e7f3d4fda8563945ddd68894355eb237e3a01
‣ Public Key:             03a667f9005f357702d8341dfa4718fb73aae590f96fb3e35c2943ec684f30d224
‣ Stacks address:         ST1FFP2RB883Y5NWM4KN86B1827JHGQ1AJ0H06EFV
‣ BTC Address:            mpBAYsNW5Cii7cVrEJKU3NPTJKw59AtEqf
‣ WIF:                    cP9TN5ztLSQvii5ExoRB3FgNXqfknF36M5mA1GxkHe7yW9PjdChg
‣ Miner Reward Recipient: ST840RBVMG3MVS1Q017AEZJWYJ2EWZZTW7E5HFEK
  ‣ Private Key:          54e1542b97ffaae69d0a5c62351d85554b8ba76ae552fc0e689a7a472690d2a801
```

### Miner 5

```text
‣ Mnemonic:               position sport mango recycle thumb gasp lens zoo stand have mass prison icon stairs average silly grid swing famous trend hover ramp bunker raw
‣ Private Key:            57e3f3bae2100348e300c48789da97e704fcdaed2e9a6327f2d2ca43039c5eb501
‣ Public Key:             021f834b1abe414bda1024b30ba936091a0f1dc8cb677f67e266797ce11956520e
‣ Stacks address:         ST17P55SW82SJ1HF0AJ6AHFV70K5S0S0YH6C8RW9T
‣ BTC Address:            mnkhnR27DddFMU6FhFvGmEQBXQ1EaWqgce
‣ WIF:                    cQXYoecjY477cZ98JLn5uwaPAYWkppk57HgW3TjEMZpyo8pqmFdC
‣ Miner Reward Recipient: STCJCDGRMFQG2V0V6FPH5AANNMMTXACXZPWDC9GY
  ‣ Private Key:          9791089c2dceaa2fd2d288a1db063d756f9499ef45aa6405a39a187e85cab21401
```
## Signer Accounts

### Signer 1

```text
‣ Mnemonic:     number pause unfold flash cover thank spray road moment scatter wreck scrap cricket enemy enlist chest all dog force magnet giggle canyon spatial such
‣ Private Key:  41634762d89dfa09133a4a8e9c1378d0161d29cd0a9433b51f1e3d32947a73dc01
‣ Public Key:   035249137286c077ccee65ecc43e724b9b9e5a588e3d7f51e3b62f9624c2a49e46
‣ STX Address:  ST24VB7FBXCBV6P0SRDSPSW0Y2J9XHDXNHW9Q8S7H
‣ BTC Address:  mt56SJB4aQRz8xA13gnkNnqxZc2dESq6Sq
‣ WIF:          cPmokz1FLbW5KyZGMeSoDBeoRB51358dPzRJatiazpjLUnfaDe55
```

### Signer 2

```text
‣ Mnemonic:     puppy ladder save liar close fix deliver later victory ugly rural artwork topic camera orphan depart power pottery retreat walk ignore army employ turkey
‣ Private Key:  9bfecf16c9c12792589dd2b843f850d5b89b81a04f8ab91c083bdf6709fbefee01
‣ Public Key:   031a4d9f4903da97498945a4e01a5023a1d53bc96ad670bfe03adf8a06c52e6380
‣ STX Address:  ST2XAK68AR2TKBQBFNYSK9KN2AY9CVA91A7CSK63Z
‣ BTC Address:  mxXw9bceXuFB6HZjqriS527kTqt5H9VczT
‣ WIF:          cSowFfhhyLhwsxCQHYzFGLKZYGjob3oQ6ZwH1v4WAAcxeb4Wn4ro
```

### Signer 3

```text
‣ Mnemonic:     want stove parent truly label duck small aspect pumpkin image purity stove pottery check voyage person weasel category cat inspire portion sun lab piece
‣ Private Key:  3ec0ca5770a356d6cd1a9bfcbf6cd151eb1bd85c388cc00648ec4ef5853fdb7401
‣ Public Key:   02007311430123d4cad97f4f7e86e023b28143130a18099ecf094d36fef0f6135c
‣ STX Address:  ST1J9R0VMA5GQTW65QVHW1KVSKD7MCGT27X37A551
‣ BTC Address:  mpgvmF9DSDBrbxUY4rbsPmWkYakoDXr19j
‣ WIF:          cPggi5foghgcKAGnbRwCLMDpQCCmWVUZ9r7PkWQ7cCfK69BWLXdk
```

## Transaction-Generation Accounts

### Account 1

```text
‣ Mnemonic:     sorry door captain volume century wood soap asset scheme idea alley mammal effort shoulder gravity car pistol reform aisle gadget gown future lawsuit tone
‣ Private Key:  e26e611fc92fe535c5e2e58a6a446375bb5e3b471440af21bbe327384befb50a01
‣ Public Key:   03fb84a4a2931e7d0ec36bf6e695233bec878fd545bad580751cf4a49d78a7bb27
‣ STX Address:  ST1YEHRRYJ4GF9CYBFFN0ZVCXX1APSBEEQ5KEDN7M
‣ BTC Address:  mruR58H7NvUgmDydv1BM8zMT8og6QxN1Rx
‣ WIF:          cVArVw9FJPeygtZhRtHJEhDqEQTeC3Ybw3UjXt1ir6RgMkMj1Mcz
```

### Account 2

```text
‣ Mnemonic:     album bid grant because narrow unusual unknown machine quick core dolphin occur repair decade toilet betray word people mule assume gesture faint trend about
‣ Private Key:  e3ebd73a51da9a2ab0c6679145420876bf4338554a8972e3ab200cef7adbec6001
‣ Public Key:   03e5049566e351debe8c4d9918faafac751fdcc0e80d3db59069b45761b39015f5
‣ STX Address:  ST1WNJTS9JM1JYGK758B10DBAMBZ0K23ADP392SBV
‣ BTC Address:  mrabBBLKnSZq8fziECh4TsNwVbmdGv6JDV
‣ WIF:          cVDkVrPTBEVa9fFGwFQT4zKi9dXFUJqLym3Ct6MJTepT6Wh5413g
```

### Account 3

```text
‣ Mnemonic:     action still web blush proud cat axis barrel tower assault cram catch more soup auction require again valley letter calm license release fruit industry
‣ Private Key:  0bfff38daea4561a4343c9b3f29bfb06e32a988868fc68beed31a6c0f6de4cf701
‣ Public Key:   03a89261c20768ce41930371cd4c0d756c872e96b8ff749ac044199cc7100ccd71
‣ STX Address:  ST1MDWBDVDGAANEH9001HGXQA6XRNK7PX7A7X8M6R
‣ BTC Address:  mq5SjFHAPh93ZnFLc6Jev8yqn2iLg28Q5B
‣ WIF:          cMz2ZSsaVgWPFUkE44zHpJepB4NdwB9L938h53hQfFoot81AZFb3
```



### Deployer Account

*Unused but funded account that may be used to deploy contracts or other txs*

```text
‣ Mnemonic:     keep can record bracket note hip face pudding castle detail few sunset review burger enhance foil lamp estate reopen butter then wasp pen kick
‣ Private Key:  27e27a9c242bcf79784bb8b19c8d875e23aaf65c132d54a47c84e1a5a67bc62601
‣ Public Key:   025fa7693cfe4b7c7beccdd9e4bfe77f77a3779d5a58faeb69ead7d1ba94d64f76
‣ STX Address:  ST2SBXRBJJTH7GV5J93HJ62W2NRRQ46XYBK92Y039
‣ BTC Address:  mwp5EpXXVsZxzQRC7yrDe1CJBsyub9f91n
‣ WIF:          cNvERZ1Ci4NQydr5dTuW8K2JuoyfjLJgYVskrLzBoXREnRVbS9qx
```
