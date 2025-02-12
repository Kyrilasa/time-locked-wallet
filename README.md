# Time-Locked Wallet

A simple Ethereum smart contract project. This contract implements a time-locked wallet that allows users to:

- Deposit ETH with a custom lock duration
- View their deposits and lock status
- Withdraw funds once the lock period expires

## Note

This is a learning project and not intended for production use. Created to gain hands-on experience with Solidity and smart contract development.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/TimeLockedWallet.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
