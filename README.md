School assignment in solidity

Smart contract for register an event than that. 

The register should close after a deadline has been met. 
The contract should include these functionallity: 
register a new event, 
open and close the  event
register attendences 
handle payment
getter function over the registered antendee per event

Requirment for VG:
atleast: 1 custom error, one require, one assert and one revert
Need to have a falback and receive functions
Distrubute and verify the contract on etherscan. And provide a link 
Atleast test coverage of 90%
Identify and implement atleast three gasoptimzing solution with an explaination.











## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

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
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
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
