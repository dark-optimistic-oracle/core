# Dark Optimistic Oracle core contracts

## How to deploy and run locally

Clone this repository (`git@github.com:dark-optimistic-oracle/core.git`) and `git@github.com:dark-optimistic-oracle/token-registry-workaround.git`.

Start a local Aleo blockchain node:
In one zsh terminal run the following:
```zsh
./run_node.sh
```
or to keep state across runs run:
```zsh
./run_node.sh --keep-state
```
to clean the state later, run:
```zsh
./run_node.sh --clean
```

To install:
```zsh
./install.sh
```

The install script is idempotent and can be safely re-run.
It deploys `dark_optimistic_oracle.aleo`, and if the program is already deployed it automatically runs `leo upgrade` instead.
It also verifies on-chain confirmation markers for deploy/upgrade and initialize, and exits on unexpected outcomes.
If initialize is rejected on-chain during a rerun (already initialized), the script treats that as a non-fatal condition and continues.

The local devnet install uses `../token-registry-workaround`. Both project-owned
programs have an explicit `@admin` constructor bound to
`aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px`, so future
deployments can be upgraded only by that admin.

## Aleo testnet

Public testnet already provides the canonical `token_registry.aleo`; do not deploy
the local workaround there. Before deployment, replace the public local-devnet
`@admin` address in `src/main.leo` with a secure, user-controlled testnet address.
Set `NETWORK=testnet`, the matching funded `PRIVATE_KEY`, and `PROTOCOL` in
`.env`, then run:

```zsh
./deploy_testnet.sh
```

The script refuses to deploy with the known devnet admin. Otherwise it builds
against the canonical registry, deploys and initializes a new
oracle, or performs an admin-authorized upgrade when the oracle already exists.
It fails closed if the official API cannot determine the current program state.

With Leo 4.3.4, the initial deployment was estimated at `21.609156` credits,
excluding the subsequent `initialize` execution. Confirm the current estimate
and fund the deployer before broadcasting.

## Demo

The demo of the complete workflow with commands that are actually executed is [here](./demo/README.md).

## Command Line Interface

The command line interface is in the `cli` folder of this repository. The commands can be run from there:

```zsh
cd cli
```

Here is a list of commands:

Each command can be run with a switch `--help` or `-h` to display the usage instructions.

`self_address.sh` - displays the address of the Dark Optimistic Oracle Aleo program.

`token_id.sh ` - displays the Token ID of the `Dark Optimistic Oracle` token (`DOOR`).

`balance.sh <token id> <address>` - displays the unauthorized balance of token id in the account with the given address. The optional `token id` defaults to the `Dark Optimistic Oracle` (`DOOR`) token.

`./authorized_balance.sh <token if> <address>` - displays the authorized balance of token id in the account with the given address. The optional `token id` defaults to the `Dark Optimistic Oracle` (`DOOR`) token.

`block.sh [<block_count>]` - shows the current block or waits for the Aleo blockchain to advance to a specific block.

`mock_block.sh [<blocks>]` - for testing purposes mocks the block number forward by a given number of block or shows the current state.

`assertion.sh [--private-key <key>] <id> <title> <content_hash> <cost> <voter_stake> <dispute_deadline_blocks> <voting_deadline_blocks>` - creates an Assertion.

`dispute.sh [--private-key <key>] <id>` - disputes the Assertion with the given ID.

`voting_right.sh [--private-key <key>] <private_payment_record> <id> <voter_stake>` - creates a private Voting Right record for the Assertion with the given ID and anticipated Voter Stake.

`confirm.sh [--private-key <key>] <voting_right>` - votes "yes" for the Assertion for which the Voting Right record was created. Creates a private Voting Receipt record.

`deny.sh [--private-key <key>] <voting_right>` - votes "no" for the Assertion for which the Voting Right record was created. Creates a private Voting Receipt record.

`asserter_collect.sh [--private-key <key>] <cost> <id>` - asserter publicly collects the partial refund for the Assertion with the given ID with anticipated Assertion Cost, in case the assertion is not disputed or confirmed via voting.

`disputer_collect.sh [--private-key <key>] <cost> <id>` - disputer publicly collects the reward for the Assertion with the given ID with anticipated Assertion Cost, in case the assertion is disputed and voted as incorrect.

`voter_collect.sh [--private-key <key>] <amount> <voting_receipt>` - voter privately collects (receives DOOR Token record) the Voting Stake and Voting Award in the anticipated amount, in case the corresponding vote was correct.

`voter_refund.sh [--private-key <key>] <refund_amount> <voting_right>` - voter privately collects (receives DOOR Token record) the unused Voting Stake refund in the anticipated amount.

`protocol_collect.sh [--private-key <key>] <amount>` - the protocol Fee Collector (Owner) publicly collects accrued fees in the given amount up to the total protocol fees accrued in the Dark Optimistic Oracle program.
