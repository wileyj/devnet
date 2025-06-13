Modified from: https://github.com/stacks-sbtc/sbtc/tree/v1.0.2/docker, changes:

- Temporarily deleted services related to sBTC
- Added 2 stacks miners, now there are 3 miners competing for mining
- Build the `stacks-core` locally instead of pull `blockstack/stacks-core` image

## Containers

- bitcoin-node:
- stacks-node:
- stacks-miner-2:
- stacks-miner-3:
- stacks-signer-1: based on `stacks-node`
- stacks-signer-2: based on `stacks-node`
- stacks-signer-3: based on `stacks-node`
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
- ? Miner Reward Recipient: STQM73RQC4EX0A07KWG1J5ECZJYBZS4SJ4ERC6WN

**Stacks Miner 2**

- Mnemonic: cherry lawn pull huge drift wisdom capable bulk tragic street first foam onion above come smart eyebrow about soon jungle select used front ecology
- Private Key: 1415e80bf3fe30fe95889c676681b4f64447f8888f718381840224b14ef4b97801
- Public Key: 03a1940aedd43c39a39c73a1686faaabc67b6bd918d9710292e6c400308df0130e
- BTC Address: mxxRn3xP98tSJCUXxABq4dgg4SziNacF1Y
- Stacks Address: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55
- WIF: cNFkBfqr4tz3V7pcKbBvcibKsZ6XnTmcTwyWoqGm4CStmqN1bqh8
- ? Miner Reward Recipient: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55

**Stacks Miner 3**

- Mnemonic: identify test gallery pave now pet just gospel erupt walnut demand oyster old trigger soup zoo sheriff oyster twenty tragic license casual twelve depth
- Private Key: c1c3f3f7bb8cc0b64c3be0f79488a3b1e3dbca62f23a5ac84e13beba78cc961301
- Public Key: 025511871cb065df0ac108d149b5abe2267242745fd02b1d7a5fafb8dcf3ad66ce
- BTC Address: miBGjFEQveJSbzFwB9XJ9a4GmkY3Unmb7b
- Stacks Address: STEJYWJ2Y7E72AF9JMRWZWNR11ADBJBHD45P7D7K
- WIF: cU5McyYQu1VJw6tzekyAJd1Jm9NVtjkPhrcbyVm8LgGdiW1Htrf4
- ? Miner Reward Recipient: ST2ZMPYMHV80HGY99P9B81CN8E66JHBYVXB8P5F55

## Key Generator

```sh
npm install --global @stacks/cli
stx make_keychain -t

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
