# Dark Optimistic Oracle core contracts

## How to deploy and run locally

Clone this repository (`git@github.com:dark-optimistic-oracle/core.git`) and `git@github.com:dark-optimistic-oracle/token_registry_workaround.git`.

In one zsh terminal run the following:
```zsh
amareleo-chain start
```

To install:
```zsh
./install.sh
```

To run without executing:
```zsh
leo run "main" "1u32" "2u32"
```

## Command Line Interface

The command line interface is in the `cli` folder of this repository. The commands can be run from there:

```zsh
cd cli
```

Here is a list of commands:

Each command can be run with a switch `--help` or `-h` to display the usage instructions.

`./self_address.sh` - displays the address of the Dark Optimistic Oracle Aleo program.

`./token_id ` - displays the Token ID of the `Dark Optimistic Oracle` token (`DOOR`).

`./balance.sh <token id> <address>` - displays the unauthorized balance of token id in the account with the given address. The optional `token id` defaults to the `Dark Optimistic Oracle` (`DOOR`) token.

`./authorized_balance.sh <token if> <address>` - displays the authorized balance of token id in the account with the given address. The optional `token id` defaults to the `Dark Optimistic Oracle` (`DOOR`) token.

