# Security audit record

This file is an append-only record of security reviews of the Dark Optimistic
Oracle core. Each review or remediation verification is a separate dated
chapter. A passing check means only that the described behavior was exercised;
it is not a guarantee that the program is free of defects.

## 2026-08-15 — Pre-remediation audit

Audit time: 2026-08-15 06:29 EDT (computer local time).

### Scope and method

The review covered `src/main.leo`, the Leo unit tests, deployment and local
devnet scripts, CLI helpers, environment-file handling, upgrade configuration,
and the oracle's integration contract with `token_registry.aleo` and the sample
prediction market. It used manual data-flow and authorization review,
adversarial lifecycle analysis, secret scanning of the current tree and Git
history, shell syntax checks, Leo 4.3.4 compilation through the isolated test
harness, and all 10 existing Leo unit tests.

### Findings

| ID | Severity | Status | Finding and impact | Recommendation |
| --- | --- | --- | --- | --- |
| CORE-2026-08-15-01 | Critical | Open | `initialize` has no administrator check. On a new network, the first caller receives the initial treasury mint and becomes `fee_collector`. The deployment script creates a public interval between deployment and initialization, so a third party can front-run it. The currently deployed Testnet instance was checked separately and has the intended fee collector; its existing state was not hijacked. | Bind initialization, its mint recipient, and the fee collector to the same administrator that controls upgrades. Preserve the program ID and current mappings so the fix can be installed as an in-place upgrade. |
| CORE-2026-08-15-02 | High | Open | Voting is described as private, but `confirm` and `deny` are distinct transition names and both aggregate counters are public. A public fee also reveals the fee-paying address, creating a strong link between a voter and a direction. Private record inputs do hide the record contents and owner from the transition inputs, but they do not make the complete action or tally private. | Use private fees for voting-related wallet calls and document the exact privacy boundary. A protocol that hides vote direction and live totals would require a separate cryptographic aggregation design. |
| CORE-2026-08-15-03 | High | Open | A voting right can be acquired until the voting deadline while the live tally is public. A late participant can observe the count and purchase enough fixed-stake rights to influence the result with little uncertainty. | Close acquisition before the vote deadline, leaving a vote-only interval. Treat full resistance to late strategic voting as an architectural follow-up requiring hidden or commit/reveal aggregation and a reviewed economic model. |
| CORE-2026-08-15-04 | Medium | Open | The unit suite tests pure majority, payout, boundary, and assertion-age helpers, but it does not execute the stateful assertion/dispute/vote/award lifecycle or adversarial authorization cases. A passing 10/10 result therefore does not validate the entire program. | Add explicit helpers and negative tests for new authorization and timing invariants, and run full local-devnet integration tests before releases. |
| CORE-2026-08-15-05 | Medium | Open | The upgrade and fee-collector authority is one externally controlled key, with no on-chain delay, multisignature approval, or recovery path. Compromise or loss of that key can produce a malicious upgrade or prevent future maintenance. | Document the trust assumption and operational controls. Move to a reviewed multisignature/timelocked administration design before production if Aleo tooling and governance permit it. |
| CORE-2026-08-15-06 | Medium | Open | CLI wrappers accept private keys as command-line values and several expand records and parameters without robust quoting. Process listings and shell history can expose supplied keys; whitespace or shell metacharacters can also make helpers behave unexpectedly. | Prefer keys loaded from mode-`600` `.env.private`, remove key examples from interactive command lines, quote every expansion, validate argument counts and literal types, and label these wrappers as local-development tools. |
| CORE-2026-08-15-07 | Medium | Open | Historical Git commits contain generic development private keys that have since been removed from the current tree. History makes those accounts permanently compromised even though real `.env*` files are now ignored. | Never fund or reuse those historical accounts on Testnet or Mainnet. Retain them only as explicitly compromised local-devnet fixtures; use separate private accounts for every public network. History rewriting is optional hygiene, not a rotation substitute. |
| CORE-2026-08-15-08 | Low | Open | The repository has a guarded Testnet upgrade script and local-devnet installer but no equivalent checked-in Mainnet deployment wrapper. Manual production steps increase configuration and wrong-network risk. | Add a non-broadcasting-by-default Mainnet wrapper with administrator/address derivation checks, explicit confirmation, canonical registry checks, and the same output redaction as Testnet. Do not use it until a production deployment is authorized. |

### Positive controls observed

- Every checked-in program declares a Leo 4 administrator constructor, so the
  oracle is upgradeable rather than permanently immutable.
- The Testnet deployment wrapper derives the public address from the private key,
  rejects the public devnet administrator, builds in a temporary directory,
  redacts private-key-looking output, and skips reinitialization when state exists.
- Real `.env*` files are ignored. The present `.env.private` is mode `600`, and no
  private key is tracked in the current tree.
- Bond bounds prevent the reviewed payout multiplications from exceeding `u128`.
  Award-claimed mappings prevent duplicate public asserter and disputer payouts;
  private records provide native one-time-spend protection for voter claims.

### Verification evidence and limits

- Leo version: 4.3.4.
- Core unit tests: 10 passed, 0 failed.
- All checked-in shell scripts parsed with `zsh -n`.
- No signed transaction was submitted during this pre-remediation chapter.
- This is an engineering security review, not a formal proof or independent
  third-party audit. The external canonical token registry, wallet extension,
  Aleo VM, prover implementation, and network consensus are dependencies outside
  this repository's audit boundary.

## 2026-08-15 — Remediation verification

Verification time: 2026-08-15 07:04 EDT (computer local time).

### Fixes and dispositions

| Finding | Disposition | Remediation and remaining risk |
| --- | --- | --- |
| CORE-2026-08-15-01 | Fixed | `initialize` now requires `std::ctx::signer()` to equal the configured protocol administrator. The initial treasury mint and fee collector are bound to that same address. Public deployment replaces both the Leo constructor administrator and initialization constant in a temporary build tree. |
| CORE-2026-08-15-02 | Mitigated | Both frontends now request private fees for the record-based voting lifecycle and describe the privacy boundary accurately. Record ownership and the fee payer can be hidden, but the `confirm`/`deny` function and aggregate tallies remain public by protocol design. |
| CORE-2026-08-15-03 | Mitigated | Buying a new voting right now closes 10 blocks before the voting deadline, leaving a vote-only interval. Strategic rights acquired earlier and public live tallies remain an economic-design risk. |
| CORE-2026-08-15-04 | Partially fixed | Authorization and right-purchase boundary helpers and negative tests were added; 14/14 hermetic Leo tests pass. A fresh stateful local-devnet adversarial run remains required before a production release. |
| CORE-2026-08-15-05 | Accepted risk | The single administrator remains necessary for the current upgrade model. Key isolation, funding separation, and explicit upgrade records are documented; multisignature/timelock governance remains future work. |
| CORE-2026-08-15-06 | Partially fixed | Documentation prefers mode-`600` `.env.private`, and queries use quiet mode. Legacy CLI argument handling remains development-only and must not be used with production secrets. |
| CORE-2026-08-15-07 | Accepted risk | Historical generic keys are explicitly treated as compromised local fixtures and are rejected by public deployment paths. Public credentials remain ignored and separate. |
| CORE-2026-08-15-08 | Open, low | The coordinated `predmkt` project provides guarded devnet, Testnet, and Mainnet dry-run wrappers. The standalone core repository still has no oracle-only Mainnet wrapper. |

### Compatibility and verification

- The program ID, all existing structs, records, and mappings are unchanged.
  No state migration or reinitialization is required.
- A first live upgrade attempt was rejected locally by Leo before broadcast
  because the candidate had removed the initializer's historical finalize input.
  The candidate was corrected to retain that captured caller and additionally
  assert that both signer and caller are the administrator. The rerun passed
  14/14 tests and compilation; no rejected-candidate transaction or fee existed.
- Public deployment builds substitute one identical administrator into both
  upgrade and initialization authorization and fail if either substitution is
  absent.
- Leo 4.4.1 compilation and 14/14 oracle tests passed after migrating to its
  `std::ctx` syntax. The release asset checksum matched the official published
  SHA-256 before use.
- The combined project compiled the oracle and market for devnet, Testnet, and
  Mainnet in dry-run mode; no dry run signed or broadcast a transaction.
- The live pre-upgrade Testnet snapshot showed oracle edition 0, the intended
  fee collector, and the representative QA assertion intact. Upgrade transaction
  evidence and the post-upgrade comparison are recorded in `LOG.md` and
  `DEPLOYMENTS.md`.

This remediation reduces the identified implementation risks but is not a
formal verification or independent third-party audit.

## 2026-08-15 — Testnet upgrade verification

Verification time: 2026-08-15 08:12 EDT (computer local time).

### Compatibility checks

- Leo `4.4.1` was used because its snarkVM/snarkOS 4.9.0 rules match active
  Testnet consensus V18. Leo `4.3.4` calculated an obsolete lower deployment
  fee; its candidate was rejected without an accepted transaction or fee.
- The initializer retains the edition-0 finalize input order while checking
  both the direct caller and signer against the configured administrator.
- The final candidate preserves the deployed program ID, constructor admin,
  every existing mapping/record/struct, every callable function, and every
  finalize input type and order. It does not reinitialize or migrate state.
- Two never-deployed audit-only helper entry points were removed from the
  candidate. The production administrator and voting-cutoff checks remain in
  `initialize` and `new_voting_right`. Both source copies pass all 10 retained
  Leo tests.

### Testnet result

The compatible oracle candidate has combined circuit density `3481397` and a
current minimum fee of `29.406397` credits. Consensus V18 permits `75000`
density units per certificate in the target block, so this deployment requires
at least 47 certificates. Every transaction that reached validators during this
session landed in a block with only 30–44 certificates and was recorded by the
ledger as aborted. Under this path the fee was not charged. Other attempts
failed at the provider with HTTP 522 before an ID was returned.

The latest verified state therefore remains:

- `dark_optimistic_oracle.aleo`: edition `0`;
- fee collector and upgrade administrator: the documented dedicated Testnet
  address;
- representative QA assertion `187031922field`: unchanged;
- security fixes: committed and release-ready, but not yet active on Testnet.

This is a network inclusion-capacity blocker, not a source-compatibility or
authorization rejection. The accepted and aborted evidence, safe retry command,
and post-attempt balance/state checks are recorded in the prediction-market and
frontend `LOG.md` files and in `DEPLOYMENTS.md`. Mainnet remains unattempted.

## 2026-08-15 — Initialization upgrade-rule assessment

Verification time: 2026-08-15 09:32 EDT (computer local time).

The active snarkVM 4.9 upgrade checker treats Aleo's special `constructor` and
an application function named `initialize` differently. A constructor cannot
be added, deleted, or modified. Existing ordinary functions and finalize scopes
may change logic provided their function input/output types and finalize-input
types remain stable. Existing imports, mappings, structs, records, and closures
must also remain compatible.

The deployed Testnet constructor and the freshly compiled candidate constructor
were compared directly and match byte-for-byte:

`assert.eq program_owner aleo1a2k4a9phy4kklx2ad0aed0lgvyzaegf0gfp85uldzhjzn8tt05zsjmfjnf;`

`initialize` remains a zero-input function returning one program future, and
its finalize inputs remain `address.public`,
`token_registry.aleo/register_token.future`, and
`token_registry.aleo/mint_public.future`. The candidate changes only internal
logic by checking signer and caller before producing those same futures.

A disposable Devnet program then tested the exact rule operationally:

- edition-0 deployment: `at1kmvyghxp3ap534sjj4rkwf9eppmmuq2upjawa0y7nn4l2hjgtuzsyn36rq`;
- edition-1 upgrade after adding administrator checks inside `initialize`:
  `at1hwq2gmu4zj4000jfjzkgn5w4sskx5jmldt5v57sqq5yakva3ac8q43djuy`;
- accepted post-upgrade `initialize` execution:
  `at1jxl4yk280d9yut0gawyqydsy4tustu6xx2zjnkc4w76wurx3tu9qrtapzg`.

The local API reported edition 1 and the initialized mapping contained the
expected Devnet administrator. This used only disposable Devnet credits. The
available snarkOS 4.8.1 fixture used consensus V17 while Leo 4.4.1 warned that
it expected V18; the constructor/function compatibility rule is the same in
the inspected active snarkVM 4.9 source, and the Testnet client already passed
that compatibility check when creating the eight broadcast candidates.

Conclusion: changing the `initialize` function is not the Testnet obstacle.
The sufficient blocker observed on every broadcast remains the candidate's
`3481397` combined deployment density: at 75,000 density units per certificate,
it needs at least 47 certificates, while the target blocks provided only
30–44. No Testnet transaction was created during this assessment.
