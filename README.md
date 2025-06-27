Modified from: https://github.com/stacks-sbtc/sbtc/tree/v1.0.2/docker, changes:

- Deleted services related to sBTC, mempool and grafana
- Added 5 stacks miners, by default there are 3 miners competing for mining
- Build the `stacks-core` image locally instead of pull `blockstack/stacks-core` image (roughly 500MB per container)

## Containers

- bitcoin: Runs a bitcoin regtest node
- bitcoin-miner: creates 5 bitcoin regtest wallets and mines regtest blocks
- stacks-seed: stacks bootstrap node, sends events to an API. peers with stacks-miner-{1,2,3}
- stacks-miner-1: mines stacks blocks and sends events to stacks-signer-1
- stacks-miner-2: mines stacks blocks and sends events to stacks-signer-2
- stacks-miner-3: mines stacks blocks and sends events to stacks-signer-3
- stacks-signer-1: event observer for stacks-miner-1
- stacks-signer-2: event observer for stacks-miner-2
- stacks-signer-3: event observer for stacks-miner-3
- stacker: stack for `stacks-signer-1`, `stacks-signer-2` and `stacks-signer-3`
- tx-broadcaster: xxx for `stacks-signer-1`, `stacks-signer-2` and `stacks-signer-3`
- monitor: xxx for `stacks-signer-1`, `stacks-signer-2` and `stacks-signer-3`

## Logs

```sh
sudo tail -f `docker inspect --format='{{.LogPath}}' stacks-signer-1`
sudo tail -f `docker inspect --format='{{.LogPath}}' stacks-miner-3`
```

## Accounts

**Stacks Miner**

- Private Key: 9e446f6b0c6a96cf2190e54bcd5a8569c3e386f091605499464389b8d4e0bfc201
- Public Key: 035379aa40c02890d253cfa577964116eb5295570ae9f7287cbae5f2585f5b2c7c
- BTC Address: miEJtNKa3ASpA19v5ZhvbKTEieYjLpzCYT
- Stacks Address: STEW4ZNT093ZHK4NEQKX8QJGM2Y7WWJ2FQQS5C19
- WIF: cStMQXkK5yTFGP3KbNXYQ3sJf2qwQiKrZwR9QJnksp32eKzef1za
- Miner Reward Recipient: STQM73RQC4EX0A07KWG1J5ECZJYBZS4SJ4ERC6WN
  - Private Key: 41aea3f0b909ab2427268e495b5238c77c04413eb75c6a2f9117b2d1e897c8f301

**Stacks Miner 2**

- Mnemonic: cherry lawn pull huge drift wisdom capable bulk tragic street first foam onion above come smart eyebrow about soon jungle select used front ecology
- Private Key: 1415e80bf3fe30fe95889c676681b4f64447f8888f718381840224b14ef4b97801
- Public Key: 03a1940aedd43c39a39c73a1686faaabc67b6bd918d9710292e6c400308df0130e
- BTC Address: mxxRn3xP98tSJCUXxABq4dgg4SziNacF1Y
- Stacks Address: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55
- WIF: cNFkBfqr4tz3V7pcKbBvcibKsZ6XnTmcTwyWoqGm4CStmqN1bqh8
- Miner Reward Recipient: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55
  - Private Key: c9f739fb35b00b78596b4ba4656ce143f95f1d9730a40309c9866470a4a7069f01

**Stacks Miner 3**

- Mnemonic: identify test gallery pave now pet just gospel erupt walnut demand oyster old trigger soup zoo sheriff oyster twenty tragic license casual twelve depth
- Private Key: c1c3f3f7bb8cc0b64c3be0f79488a3b1e3dbca62f23a5ac84e13beba78cc961301
- Public Key: 025511871cb065df0ac108d149b5abe2267242745fd02b1d7a5fafb8dcf3ad66ce
- BTC Address: miBGjFEQveJSbzFwB9XJ9a4GmkY3Unmb7b
- Stacks Address: STEJYWJ2Y7E72AF9JMRWZWNR11ADBJBHD45P7D7K
- WIF: cU5McyYQu1VJw6tzekyAJd1Jm9NVtjkPhrcbyVm8LgGdiW1Htrf4
- Miner Reward Recipient: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55
  - Private Key: 357e5e4bb609bd9e811a4105384926ddfbd755f30c18649fe405c7c57c55b58601


**Stacks Miner 4**
- Mnemonic: report weasel jealous pizza long order section oak dignity radar combine project broom glass bridge pulp glory magic dutch toe undo patient photo core
- Private Key: 2eafe91d1bf9a37a650717f208d16e7f3d4fda8563945ddd68894355eb237e3a01
- Public Key: 03a667f9005f357702d8341dfa4718fb73aae590f96fb3e35c2943ec684f30d224
- Stacks address: ST1FFP2RB883Y5NWM4KN86B1827JHGQ1AJ0H06EFV
- BTC Address: mpBAYsNW5Cii7cVrEJKU3NPTJKw59AtEqf
- WIF: cP9TN5ztLSQvii5ExoRB3FgNXqfknF36M5mA1GxkHe7yW9PjdChg
- Miner Reward Recipient: ST840RBVMG3MVS1Q017AEZJWYJ2EWZZTW7E5HFEK
  - Private Key: 54e1542b97ffaae69d0a5c62351d85554b8ba76ae552fc0e689a7a472690d2a801


**Stacks Miner 5**
- Mnemonic: position sport mango recycle thumb gasp lens zoo stand have mass prison icon stairs average silly grid swing famous trend hover ramp bunker raw",
- Private Key: 57e3f3bae2100348e300c48789da97e704fcdaed2e9a6327f2d2ca43039c5eb501",
- Public Key: 021f834b1abe414bda1024b30ba936091a0f1dc8cb677f67e266797ce11956520e",
- Stacks address: ST17P55SW82SJ1HF0AJ6AHFV70K5S0S0YH6C8RW9T",
- BTC Address: mnkhnR27DddFMU6FhFvGmEQBXQ1EaWqgce",
- WIF: cQXYoecjY477cZ98JLn5uwaPAYWkppk57HgW3TjEMZpyo8pqmFdC",
- Miner Reward Recipient: STCJCDGRMFQG2V0V6FPH5AANNMMTXACXZPWDC9GY
  - Private Key: 9791089c2dceaa2fd2d288a1db063d756f9499ef45aa6405a39a187e85cab21401


## Key Generator

```sh
npm install --global @stacks/cli
stx make_keychain -t 2>/dev/null | jq

#
# '-t' option makes this a testnet account
#
# Output
# - mnemonic:           A 24-word seed phrase used to access the account, generated using BIP39 with 256 bits of entropy
# - keyInfo.privateKey: Private key for the account. Required for token transfers and often referred to as senderKey
# - keyInfo.address:    Stacks address for the account
# - keyInfo.btcAddress: Corresponding BTC address for the account.
# - keyInfo.wif:        Private key of the btcAddress in compressed format.
# - keyInfo.index:      Nonce for the account, starting at 0
#
# see https://docs.stacks.co/concepts/network-fundamentals/accounts#creation
#
```
