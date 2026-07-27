# Network addresses and deployments

Last verified: 2026-07-27

No private key is recorded here. Real keys remain only in the ignored,
mode-`600` `.env.private` file.

## Testnet

### Accounts

| Address | Role |
| --- | --- |
| `aleo1a2k4a9phy4kklx2ad0aed0lgvyzaegf0gfp85uldzhjzn8tt05zsjmfjnf` | Dedicated shared deployer, upgrade administrator, oracle fee collector, and initial DOOR recipient. This is the address to fund for later Testnet deployments or upgrades. Its key is `TESTNET_PRIVATE_KEY`. |
| `aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px` | Retained generic devnet account that temporarily received faucet funds and relayed them to the dedicated Testnet account. Do not use it as a public-network administrator. Its retained key is `DEVNET_PRIVATE_KEY`. |

After deployment, the dedicated account had `11.723278` public credits and the
relay account had `0.538849` public credits. Faucet balances change over time;
query them with `leo -q query` before relying on these values.

### Programs

| Program | Deterministic program address | Testnet state |
| --- | --- | --- |
| `dark_optimistic_oracle.aleo` | `aleo1nyflwg9mjfkfp2n9mtng0snxj9qrhahkjxp5l9pag4zxm3qrssrqwv8tml` | Deployed at edition `0` and initialized. |
| `token_registry.aleo` | Canonical Aleo program; not deployed or administered by this project. | Existing public dependency, edition `1` when deployment was performed. |

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
