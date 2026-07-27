# Local devnet demo

This guide exercises the complete protocol workflow on the local devnet. The
included development accounts are disposable local-only identities. Their
credentials are retained in the ignored `.env.private` file under `DEVNET_*`
names and must never be reused on Testnet or Mainnet.

## Accounts and Roles

Public addresses and local-network settings belong in `.env`. The corresponding
private credentials belong in `.env.private` as `DEVNET_PRIVATE_KEY`,
`DEVNET_PROTOCOL_PK`, `DEVNET_ASSERTER_PK`, `DEVNET_DISPUTER_PK`, and
`DEVNET_VOTER_<n>_PK`.

### Owner

The Owner installs `dark_optimistic_oracle.aleo` and acts as the protocol fee
collector.

In addition, the Owner shall receive the entire token supply that will ever be minted without the protocol operation.
This account is responsible to distribute this supply to the Treasury, Founders, Investors, etc. This may
involve distribution to programs that would enforce Vesting and other restrictions.

Load the public and private local configuration, then confirm the Owner address:

```zsh
. ./.env
. ./.env.private
leo account import "$DEVNET_PRIVATE_KEY"
```

Leo reports the corresponding public address:

```
Address  aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px
```

This account in Amareleo (the development local node) shall further distribute funds to the other accounts.

### Asserter

The retained `DEVNET_ASSERTER_PK` corresponds to:

`aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca`

### Disputer

The retained `DEVNET_DISPUTER_PK` corresponds to:

`aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52`

### Voters

#### Voter 1

The retained `DEVNET_VOTER_1_PK` corresponds to:

`aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw`

#### Voter 2

The retained `DEVNET_VOTER_2_PK` corresponds to:

`aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6`

#### Voter 3

The retained `DEVNET_VOTER_3_PK` corresponds to:

`aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah`

## Calling Workflow

### Install

Install the program dark_optimistic_oracle.aleo and its dependencies:
```zsh
./install.sh
```

The installer is safe to run multiple times.
If `dark_optimistic_oracle.aleo` is already deployed, it automatically switches to upgrade.
The script waits for on-chain confirmation of deploy/upgrade and initialize, and fails on unexpected results.
On reruns, initialize may be rejected because the program is already initialized; this is handled as a non-fatal case.

### Fund the accounts

We will not use relayers for this demo. Each account will broadcast its own calls.
For that, each account will need some Aleo credits, and some DOOR tokens.

We can see how much the Owner account has in Aleo credits:
```zsh
leo -q query program credits.aleo --mapping-value account $PROTOCOL
```

and how much in DOOR tokens (from the `cli` folder):
```zsh
./authorized_balance.sh $PROTOCOL 
```

Let's give one Aleo credit to each of the participants' accounts (from the top folder):
```zsh
. ./.env
. ./.env.private
leo execute credits.aleo::transfer_public "$ASSERTER" 1_000_000u64 --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
leo execute credits.aleo::transfer_public "$DISPUTER" 1_000_000u64 --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
leo execute credits.aleo::transfer_public "$VOTER_1" 1_000_000u64 --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
leo execute credits.aleo::transfer_public "$VOTER_2" 1_000_000u64 --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
leo execute credits.aleo::transfer_public "$VOTER_3" 1_000_000u64 --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
```
as well as DOOR tokens. The Asserter and Disputer need 100 public DOOR balance (from the top folder):
```zsh
. ./.env
. ./.env.private
leo execute token_registry.aleo::transfer_public "$DOOR" "$ASSERTER" 100_000_000u128 --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
leo execute token_registry.aleo::transfer_public "$DOOR" "$DISPUTER" 100_000_000u128 --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
```
while the voters will get 1 private DOOR balance. For Voter 1 (from the top folder):
```zsh
. ./.env
. ./.env.private
leo execute token_registry.aleo::transfer_public_to_private "$DOOR" "$VOTER_1" 1_000_000u128 false --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
```
> **Note:** `snarkos developer scan` requires a local devnet node with record scanning support. The record shown below was captured from the Leo CLI output during execution. In production the record would be found via `snarkos developer scan` or your wallet.

To see this record:
```zsh
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_1_PK --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 7217685150051585053344308293369013275054479635381924146506947736298899083074group.public,  _version: 1u8.public}
```
for Voter 2  (from the top folder):
```zsh
leo execute token_registry.aleo::transfer_public_to_private "$DOOR" "$VOTER_2" 1_000_000u128 false --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_2_PK --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 3830038482030342871309118528480031319148988891247769800609217187153329494106group.public,  _version: 1u8.public}
```
and for Voter 3  (from the top folder):
```zsh
leo execute token_registry.aleo::transfer_public_to_private "$DOOR" "$VOTER_3" 1_000_000u128 false --private-key "$DEVNET_PRIVATE_KEY" --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_3_PK --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 1821246135261158736032948967207899841198532078809598323958750579941166808578group.public,  _version: 1u8.public}
```

# DEMO STARTS HERE


### Create an assertion

The Asserter creates an assertion (from the `cli` folder):
```zsh
./assertion.sh --private-key $DEVNET_ASSERTER_PK 123field 456field 789field 100_000_000u128 1_000_000u128 10000 20000
```

### Dispute the assertion

Before the deadline to dispute, the Disputer can dispute the above assertion (from the `cli` folder):
```zsh
./dispute.sh --private-key $DEVNET_DISPUTER_PK 123field 100_000_000u128
```

### Vote on the assertion

Each voter has to execute the following steps:
- Purchase a Voting Right
- Vote (either Confirm or Deny)
- Collect the voting award
- Get refund for the Voting Right in case it was not used (did not vote) by the deadline

#### Purchase Voting Right

Voter 1 can first pay to obtain a voting right (from the `cli` folder):
```zsh
./voting_right.sh --private-key $DEVNET_VOTER_1_PK\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 7217685150051585053344308293369013275054479635381924146506947736298899083074group.public,  _version: 1u8.public}"\
  123field 1_000_000u128
```
and check:
```
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  _nonce: 1916322672018147382854707312202085214777761072431433941899130795808197826813group.public,  _version: 1u8.public}
```

Voter 2 can first pay to obtain a voting right (from the `cli` folder):
```zsh
./voting_right.sh --private-key $DEVNET_VOTER_2_PK\
  "{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 3830038482030342871309118528480031319148988891247769800609217187153329494106group.public,  _version: 1u8.public}"\
  123field 1_000_000u128
```

and check:
```
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  _nonce: 5145392843603465884638322010069398038155323606269887637432650732346778420445group.public,  _version: 1u8.public}
```

Voter 3 can first pay to obtain a voting right (from the `cli` folder):
```zsh
./voting_right.sh --private-key $DEVNET_VOTER_3_PK\
  "{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 1821246135261158736032948967207899841198532078809598323958750579941166808578group.public,  _version: 1u8.public}"\
  123field 1_000_000u128
```

and check:
```
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  _nonce: 2228793572373916095403397020559608317613410552118554715065914632061237503421group.public,  _version: 1u8.public}
```

#### Vote

Voter 1 will confirm the assertion (from the `cli` folder):
```zsh
./confirm.sh --private-key $DEVNET_VOTER_1_PK\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 1916322672018147382854707312202085214777761072431433941899130795808197826813group.public,  _version: 1u8.public}"
```
and check:
```
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 8401380187321425398524037599072863595607808281814913320810389875998654131179group.public,  _version: 1u8.public}
```

Voter 2 will confirm the assertion (from the `cli` folder):
```zsh
./confirm.sh --private-key $DEVNET_VOTER_2_PK\
  "{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  _nonce: 5145392843603465884638322010069398038155323606269887637432650732346778420445group.public,  _version: 1u8.public}"
```
and check:
```
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 159924143601799761962011034886484301652097082187720269676620825591757827820group.public,  _version: 1u8.public}
```

Voter 3 will deny the assertion (from the `cli` folder):
```zsh
./deny.sh --private-key $DEVNET_VOTER_3_PK\
  "{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  _nonce: 2228793572373916095403397020559608317613410552118554715065914632061237503421group.public,  _version: 1u8.public}"
```
and check:
```
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  outcome: false.private,  _nonce: 656551087031393785562663902817845772501217325905334155737251563023111273885group.public,  _version: 1u8.public}
```

### See the voting result

Advance the local devnode by real blocks. On Testnet or Mainnet, wait for the
required deadline instead (from the `cli` folder):
```zsh
./mock_block.sh 20000u32
```

### Asserter or Disputer collects award

Since the assertion was disputed and confirmed, the asserter can collect both
the refund and counterparty stake (from the `cli` folder):
```zsh
./asserter_collect.sh --private-key $DEVNET_ASSERTER_PK\
  123field 190_000_000u128
```
and check:
```zsh
./authorized_balance.sh $ASSERTER 
```
which yields the refund record:
```zsh
{
  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field,
  account: aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca,
  balance: 190000000u128,
  authorized_until: 4294967295u32
}
```

If the disputer were right, he would collect the refund and award (from the `cli` folder):

```zsh
./disputer_collect.sh --private-key $DEVNET_DISPUTER_PK\
  123field 190_000_000u128
```
and check:
```zsh
./authorized_balance.sh $DISPUTER 
```
which should yields the refund record, but this time the transaction would fail as the disputer was not right and obtain nothing:
```zsh
{
  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field,
  account: aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52,
  balance: 0u128,
  authorized_until: 4294967295u32
}
```

### Voter collect awards

The voter can either collect the award for timely correct voting or get a refund for the Voting Right that was not used.

#### Collect voting award

If the Voter voted on time, they can collect the award for the correct voting. If the vote was not correct
there is nothing to collect, so the collection would yield a private DOOR Token in the amount of 0.

We have to pre-calculate the amount of the award, which is $1,000,000 * (100 + 1) / 100 = 1,010,000.

Voter 1 can collect (from the `cli` folder):
```zsh
./voter_collect.sh --private-key $DEVNET_VOTER_1_PK\
  1_010_000u128\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 8401380187321425398524037599072863595607808281814913320810389875998654131179group.public,  _version: 1u8.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields refund and voting award record:
```zsh
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1010000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 0u32.private,  _nonce: 3450129190593214772464100300479944533960860462932356027661713991859797398264group.public,  _version: 1u8.public}
```

Voter 2 can collect (from the `cli` folder):
```zsh
./voter_collect.sh --private-key $DEVNET_VOTER_2_PK\
  1_010_000u128\
  "{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 159924143601799761962011034886484301652097082187720269676620825591757827820group.public,  _version: 1u8.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields refund and voting award record:
```zsh
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1010000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 0u32.private,  _nonce: 1944177465688844584201647698600267726666675306308852162579909131336816946708group.public,  _version: 1u8.public}
```

Voter 3 can try to collect (from the `cli` folder):
```zsh
./voter_collect.sh --private-key $DEVNET_VOTER_3_PK\
  1_010_000u128\
  "{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  outcome: false.private,  _nonce: 656551087031393785562663902817845772501217325905334155737251563023111273885group.public,  _version: 1u8.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields nothing for refund and voting award, because of the incorrect voting - he got slashed:
```zsh
Scanning 10 blocks for records (100% complete)...   

No records found
```
no matter how many times we try this - the transaction failed.

#### Get Refund for unused Voting Right

If the voter did not vote on time they can get a refund for the VotingRight (from the `cli` folder):
```zsh
./voter_refund.sh --private-key $DEVNET_VOTER_1_PK\
  1_000_000u128\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  _nonce: 1916322672018147382854707312202085214777761072431433941899130795808197826813group.public,  _version: 1u8.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $DEVNET_VOTER_1_PK --endpoint $ENDPOINT --last 10
```
but obviously, since Voter 1 actually voted, he cannot get a refund.

### Protocol collects fees

At any time the protocol can collect any part of the the fees accrued:

```zsh
./protocol_collect.sh 1_000u128
```
and see the new balance:
```zsh
./authorized_balance.sh $PROTOCOL
```
showing:
```
{
  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field,
  account: aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px,
  balance: 9999999794001000u128,
  authorized_until: 0u32
}
```
which is up by 1000u128 from the previous balance of 9999999794000000u128.
