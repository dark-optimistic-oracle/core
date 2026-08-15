# Development Notes

Last updated: 2026-08-15

## Responsibility

This repository contains the upgradeable `dark_optimistic_oracle.aleo`
program, local-devnet operator scripts, its command-line helpers, and the
standalone oracle unit tests.

The oracle source is kept byte-for-byte aligned with
`predmkt/contracts/oracle/src/main.leo`. The prediction-market repository is
the coordinated deployment project when both the oracle and sample market are
needed.

## Contract work completed

- Replaced mock time with Aleo `block.height`.
- Added minimum deadline windows and safe arithmetic bounds.
- Added one-time claim guards for asserter and disputer awards.
- Added `verify_assertion_outcome` so consumer programs can bind an assertion
  ID, title, content hash, result, and minimum creation height.
- Added pure tested helpers for majority, award, and freshness rules.
- Updated the DOOR token identifier consistently across source and local
  configuration.
- Retained the Leo 4 `@admin` constructor. Public deployment replaces the
  checked-in local administrator only inside a temporary build tree.
- Bound initialization, the initial DOOR treasury mint, and the fee collector
  to that same administrator, closing first-caller initialization.
- Closed voting-right acquisition 10 blocks before the voting deadline, leaving
  a vote-only interval; direction and aggregate tallies remain public.

## Configuration and credentials

All real `.env*` files are ignored. Sanitized `*.example` files are the only
exceptions.

- `.env` contains public local-devnet settings and addresses.
- `.env.testnet` contains public Testnet settings.
- `.env.private` is mode `600` and contains the retained generic local accounts
  under `DEVNET_*` plus the separate `TESTNET_PRIVATE_KEY`.

The generic devnet credentials must not be reused on a public network. The
current public Testnet administrator is:

`aleo1a2k4a9phy4kklx2ad0aed0lgvyzaegf0gfp85uldzhjzn8tt05zsjmfjnf`

## Scripts

- `run_node.sh` starts or clears the local Leo devnet and loads the local
  public/private configuration without shell tracing. `--install` delegates
  the compatible snarkOS installation to Leo and stores the ignored binary at
  `./snarkos`.
- `install.sh` deploys or upgrades the local registry workaround and oracle,
  skips completed initialization through mapping checks, and verifies that
  fallback transaction lookups are accepted rather than fee-only rejections.
- `test.sh` copies the oracle and registry into a temporary tree so Leo tests
  do not attempt to install the live canonical registry into a test ledger.
- `deploy_testnet.sh` verifies that the Testnet key controls the configured
  administrator, substitutes it into upgrade and initialization authorization,
  builds against canonical `token_registry.aleo`, and deploys
  or upgrades with confirmation checks. Public initialization executes the
  deployed program directly, while `--resume` safely skips an already accepted
  deployment.
- CLI mapping queries use `leo -q query` so Leo does not print loaded `.env`
  contents.

## Validation

```zsh
./test.sh
zsh -n *.sh cli/*.sh
git diff --check
```

The current unit result is 14/14 passing. The same oracle source also passes
inside the combined prediction-market suite. A full deployed local lifecycle
also passed in `predmkt`: market creation, post-close assertion, grace-period
wait, undisputed settlement, full winning-supply burn, and redemption of the
combined collateral pool.

Local validation used Leo `4.3.4`, snarkOS `4.8.1` with the `test_network`
feature, and the explicit 17-entry consensus schedule through height 20. Leo
normally builds that snarkOS itself. On this macOS host its installer could not
resolve Xcode's `@rpath/libclang.dylib`, so validation used a manually built
binary of the same compatible version at the same ignored `./snarkos` path.
This is a host-toolchain fallback, not a second runtime dependency.

## Public deployment status

`dark_optimistic_oracle.aleo` was originally deployed to Testnet at edition `0`
and initialized against the canonical `token_registry.aleo`. Its 2026-08-15
security upgrade and preserved-state checks are recorded in `DEPLOYMENTS.md`
and `LOG.md`. Its configured admin,
fee collector, and initial DOOR recipient are the dedicated shared Testnet
account documented in [DEPLOYMENTS.md](DEPLOYMENTS.md). The prediction-market
repository performed the coordinated deployment, so rerunning the standalone
core script without intending an upgrade would spend an unnecessary upgrade
fee.

The public API verified the program, its edition, and the initialized
`fee_collector` mapping. Public API consumers now use Provable's `/v2` endpoint;
the frontend also falls back between the two official `/v2` hosts during
temporary propagation differences.

After the later funding transfer and all three accepted transactions, the
dedicated deployer retained `11.723278` public Testnet credits. Request future
deployment or upgrade funds for that dedicated address, not the retained
generic devnet account.

The dated engineering audit, remediation dispositions, and explicitly accepted
residual risks are in [AUDIT.md](AUDIT.md).
