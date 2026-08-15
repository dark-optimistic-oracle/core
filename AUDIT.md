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
| CORE-2026-08-15-01 | Fixed | `initialize` now requires `self.signer` to equal the configured protocol administrator. The initial treasury mint and fee collector are bound to that same address. Public deployment replaces both the Leo constructor administrator and initialization constant in a temporary build tree. |
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
- Public deployment builds substitute one identical administrator into both
  upgrade and initialization authorization and fail if either substitution is
  absent.
- Leo 4.3.4 compilation and 14/14 oracle tests passed.
- The combined project compiled the oracle and market for devnet, Testnet, and
  Mainnet in dry-run mode; no dry run signed or broadcast a transaction.
- The live pre-upgrade Testnet snapshot showed oracle edition 0, the intended
  fee collector, and the representative QA assertion intact. Upgrade transaction
  evidence and the post-upgrade comparison are recorded in `LOG.md` and
  `DEPLOYMENTS.md`.

This remediation reduces the identified implementation risks but is not a
formal verification or independent third-party audit.
