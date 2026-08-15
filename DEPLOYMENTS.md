# Network addresses and deployments

Last verified: 2026-08-15 10:18 EDT

No private key is recorded here. Real keys remain only in the ignored,
mode-`600` `.env.private` file.

## Testnet

### Accounts

| Address | Role |
| --- | --- |
| `aleo1a2k4a9phy4kklx2ad0aed0lgvyzaegf0gfp85uldzhjzn8tt05zsjmfjnf` | Dedicated shared deployer, upgrade administrator, oracle fee collector, and initial DOOR recipient. This is the address to fund for later Testnet deployments or upgrades. Its key is `TESTNET_PRIVATE_KEY`. |
| `aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px` | Retained generic devnet account that temporarily received faucet funds and relayed them to the dedicated Testnet account. Do not use it as a public-network administrator. Its retained key is `DEVNET_PRIVATE_KEY`. |

After the accepted prediction-market and oracle edition-1 upgrades, the shared
dedicated account had `919.621364` public credits. Faucet
balances change over time; query them with `leo -q query` before relying on this
point-in-time value.

### Programs

| Program | Deterministic program address | Testnet state |
| --- | --- | --- |
| `dark_optimistic_oracle.aleo` | `aleo1nyflwg9mjfkfp2n9mtng0snxj9qrhahkjxp5l9pag4zxm3qrssrqwv8tml` | Upgraded in place to edition `1`; initialization and existing mappings were preserved. |
| `token_registry.aleo` | `aleo1m50rc7x4cgsr5y8h2s3d6f7rzm5tvz5zqcz7ak55gmkv76pgu5qsuyq0k7` | Canonical public dependency, edition `1` when deployment was performed; not deployed or administered by this project. |

Program addresses belong to program IDs and have no user-held private key. The
oracle program address is the token-registry administrator/external-party value
used for the DOOR registration. The account administrator above controls Aleo
program upgrades through the Leo `@admin` constructor.

### Accepted Testnet transactions

| Operation | Transaction ID |
| --- | --- |
| Transfer `40` public credits from the relay account to the dedicated deployer | `at1tetgzhg9rpgdvwhwt3mtvn28a5kjw5m5j3s0p9h869j4jgdgrvpqe7kw0g` |
| Deploy `dark_optimistic_oracle.aleo` | `at1lm5mwg6427uhnpqpps6n6jcxz7qvec0d6srsxnl3r93y7cydxvgszcauw8` |
| Initialize the oracle and register DOOR | `at13teruy8sz5y3awfhlxhz45caz4er85eaed4ga4g5x7f6545rwupqd3a4vv` |
| Upgrade `dark_optimistic_oracle.aleo` to edition 1 | `at1900gz2klm9we2deqarpv2fpqhnjqjr3cvr43stxq4525l6s9zupq6r0v5p` |

### 2026-08-15 upgrade status

Leo 4.4.1 calculated the compatible oracle candidate at `3481397` combined
density and `29.406397` credits. Active consensus V18 gives each target-block
certificate 75,000 density units, so the transaction requires at least 47
certificates. Eight public candidate IDs landed in blocks containing 30–44
certificates and appear only in those blocks' `aborted_transaction_ids` lists.
They charged no fee and did not change the program or its mappings. Several
provider HTTP 522 failures happened before an ID was returned and likewise made
no ledger change.

The next controlled candidate landed in block `18745064`, whose 78 certificates
provided sufficient capacity, and was accepted as edition 1 in transaction
`at1900gz2klm9we2deqarpv2fpqhnjqjr3cvr43stxq4525l6s9zupq6r0v5p`. Its fee
transition is
`au1w9s7u95tn5h0lgn9gf5nvvwm4sh3gymjzpzprkvckfg2ypu2qq8q8ap0e4`; the public
fee was `29.406397` credits. The fee collector and representative assertion
`187031922field` were verified unchanged after acceptance. Exact candidate IDs,
blocks, certificate counts, and state evidence are recorded in the checked-in
frontend and prediction-market `LOG.md` files.

The DOOR token ID is
`346688784394585735039324415800163929700021701423791533632764818774905958305field`.

## Local devnet

Local devnet state and balances are disposable. These public demo addresses are
retained only so the scripts and walkthrough are reproducible:

| Address | Role |
| --- | --- |
| `aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px` | Protocol administrator, local deployer, local registry administrator, and fee collector. |
| `aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca` | Demo asserter. |
| `aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52` | Demo disputer. |
| `aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw` | Demo voter 1. |
| `aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6` | Demo voter 2. |
| `aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah` | Demo voter 3. |

The corresponding retained keys are named `DEVNET_PROTOCOL_PK`,
`DEVNET_ASSERTER_PK`, `DEVNET_DISPUTER_PK`, and `DEVNET_VOTER_<n>_PK` in
`.env.private`. The generic local key also remains available as
`DEVNET_PRIVATE_KEY`. None of these addresses needs Testnet faucet funds for a
local run; Leo's devnet genesis supplies local credits.

The program IDs and their deterministic program addresses are the same on
devnet and Testnet. Devnet deployments are separate local ledger entries and
are lost when the local chain is cleaned.
