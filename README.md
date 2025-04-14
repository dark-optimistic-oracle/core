# Dark Optimistic Oracle core contracts

## How to deploy and run locally

Clone this repository (`git@github.com:dark-optimistic-oracle/core.git`) and `git@github.com:dark-optimistic-oracle/token-registry-workaround.git`.

In one zsh terminal run the following:
```zsh
amareleo-chain start
```
or to keep state across runs run:
```zsh
amareleo-chain start  --keep-state
```

To install:
```zsh
./install.sh
```

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

`deny.sh [--private-key <key>] <voting_right>` - votes "yes" for the Assertion for which the Voting Right record was created. Creates a private Voting Receipt record.

`asserter_collect.sh [--private-key <key>] <cost> <id>` - asserter publicly collects the partial refund for the Assertion with the given ID with anticipated Assertion Cost, in case the assertion is not disputed or confirmed via voting.

`disputer_collect.sh [--private-key <key>] <cost> <id>` - disputer publicly collects the reward for the Assertion with the given ID with anticipated Assertion Cost, in case the assertion is disputed and voted as incorrect.

`voter_collect.sh [--private-key <key>] <amount> <voting_receipt>` - voter privately collects (receives DOOR Token record) the Voting Stake and Voting Award in the anticipated amount, in case the corresponding vote was correct.

`voter_refund.sh [--private-key <key>] <refund_amount> <voting_right>` - voter privately collects (receives DOOR Token record) the unused Voting Stake refund in the anticipated amount.

`protocol_collect.sh [--private-key <key>] <amount>` - the protocol Fee Collector (Owner) publicly collects accrued fees in the given amount up to the total protocol fees accrued in the Dark Optimistic Oracle program.
