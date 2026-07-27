# Dark Optimistic Oracle core contracts

## How to deploy and run locally

Clone this repository (`git@github.com:dark-optimistic-oracle/core.git`) and `git@github.com:dark-optimistic-oracle/token-registry-workaround.git`.

Copy the public local configuration and the ignored private credential template:

```zsh
cp .env.example .env
cp .env.private.example .env.private
chmod 600 .env.private
```

The retained demo credentials are named `DEVNET_PRIVATE_KEY`,
`DEVNET_PROTOCOL_PK`, `DEVNET_ASSERTER_PK`, `DEVNET_DISPUTER_PK`, and
`DEVNET_VOTER_<n>_PK`. Never use those development keys on Testnet or Mainnet.

Start a local Aleo blockchain node. On the first run, let Leo install the
compatible snarkOS binary into the ignored `./snarkos` path:

```zsh
./run_node.sh --install
```

Leo owns this installation through `leo devnet --install`; a separately
installed global snarkOS is neither required nor selected by the script.
Subsequent starts can reuse the local binary:

```zsh
./run_node.sh
```

State is retained across ordinary restarts. To clear the state, run:

```zsh
./run_node.sh --clean
```

On macOS, snarkOS compilation requires the Xcode/LLVM `libclang` runtime. If
the Leo installer reports `Library not loaded: @rpath/libclang.dylib`, install
or repair Xcode command-line tools and expose Xcode's `libclang` before retrying
`./run_node.sh --install`. Do not silently substitute an unrelated snarkOS
release: Leo's consensus-height schedule and the snarkOS `test_network` feature
must remain compatible.

To install:
```zsh
./install.sh
```

The install script is idempotent and can be safely re-run.
It deploys `dark_optimistic_oracle.aleo`, and if the program is already deployed it automatically runs `leo upgrade` instead.
It verifies accepted transaction types for deploy/upgrade and initialize rather
than treating a fee-only rejected transaction as success. Initialization is
skipped when the on-chain mapping already proves it was completed.

The local devnet install uses `../token-registry-workaround`. Both project-owned
programs have an explicit `@admin` constructor bound to
`aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px`, so future
deployments can be upgraded only by that admin.

Run the hermetic Leo unit tests without starting a devnet:

```zsh
./test.sh
```

The test runner uses the local token-registry implementation only in a
temporary directory. Production and public-testnet builds continue to resolve
the canonical `token_registry.aleo`.

## Aleo testnet

Public testnet already provides the canonical `token_registry.aleo`; do not deploy
the local workaround there. Copy `.env.testnet.example` to `.env.testnet`, set
its public `PROTOCOL` address, and put the matching funded key in
`TESTNET_PRIVATE_KEY` inside `.env.private`. The deployment script substitutes
the secure administrator only in a temporary build tree; it never writes the
testnet address or key into contract source.

```zsh
./deploy_testnet.sh
```

Use `./deploy_testnet.sh --resume` after an interrupted run whose deployment
transaction may already have been accepted. It verifies and skips an existing
program instead of paying for an unnecessary upgrade.

The script refuses to deploy with the known devnet admin. Otherwise it builds
against the canonical registry, deploys and initializes a new
oracle, or performs an admin-authorized upgrade when the oracle already exists.
It fails closed if the official API cannot determine the current program state.

The shared oracle is now deployed and initialized on Testnet. See
[DEPLOYMENTS.md](DEPLOYMENTS.md) for its program address, administrator,
accepted transaction IDs, and the distinct local-devnet account roles. The
combined oracle-plus-market deployment is recorded in the `predmkt` repository.

Deployment and initialization fees depend on the compiled program and current
network rules. Fund the deployer before broadcasting and retain enough public
credits for both transactions.

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

`mock_block.sh [<blocks>]` - advances a local devnode by real blocks, or shows the current height when called without arguments.

`assertion.sh [--private-key <key>] <id> <title> <content_hash> <cost> <voter_stake> <dispute_deadline_blocks> <voting_deadline_blocks>` - creates an Assertion.

`dispute.sh [--private-key <key>] <id> <cost>` - disputes the Assertion with the given ID by paying the assertion's declared cost.

`voting_right.sh [--private-key <key>] <private_payment_record> <id> <voter_stake>` - creates a private Voting Right record for the Assertion with the given ID and anticipated Voter Stake.

`confirm.sh [--private-key <key>] <voting_right>` - votes "yes" for the Assertion for which the Voting Right record was created. Creates a private Voting Receipt record.

`deny.sh [--private-key <key>] <voting_right>` - votes "no" for the Assertion for which the Voting Right record was created. Creates a private Voting Receipt record.

`asserter_collect.sh [--private-key <key>] <id> <payout_amount>` - asserter publicly collects the protocol-validated payout after the relevant dispute or voting deadline.

`disputer_collect.sh [--private-key <key>] <id> <payout_amount>` - disputer publicly collects the protocol-validated payout when the disputed assertion is rejected.

`voter_collect.sh [--private-key <key>] <amount> <voting_receipt>` - voter privately collects (receives DOOR Token record) the Voting Stake and Voting Award in the anticipated amount, in case the corresponding vote was correct.

`voter_refund.sh [--private-key <key>] <refund_amount> <voting_right>` - voter privately collects (receives DOOR Token record) the unused Voting Stake refund in the anticipated amount.

`protocol_collect.sh [--private-key <key>] <amount>` - the protocol Fee Collector (Owner) publicly collects accrued fees in the given amount up to the total protocol fees accrued in the Dark Optimistic Oracle program.
