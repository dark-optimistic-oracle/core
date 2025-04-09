# Demo

The full workflow of the protocol is described and tried.

## Accounts and Roles

Let's set up several roles and accounts for them. Let's then modify the `.env` file to contain these private keys and addresses (PROTOCOL_PK, PROTOCOL, 
ASSERTER_PK, ASSERTER, DISPUTER_PK, DISPUTER, VOTER_1_PK, VOTER_1, VOTER_2_PK, VOTER_2, VOTER_3_PK, VOTER_3):

### Owner

The Owner will launch install `dark_optimistic_oracle.aleo` and take the role of fee collector (profit collector).

In addition, the Owner shall receive the entire token supply that will ever be minted without the protocol operation.
This account is responsible to distribute this supply to the Treasury, Founders, Investors, etc. This may
involve distribution to programs that would enforce Vesting and other restrictions.

As the file `/.env` contains the private key (disclosed for testing), we can get the Owner account details as follows:
```zsh
. ./.env
leo account import $PRIVATE_KEY
```
and we get:
```
  Private Key  APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH
     View Key  AViewKey1mSnpFFC8Mj4fXbK5YiWgZ3mjiV8CxA79bYNa8ymUpTrw
      Address  aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px
```

This account in Amareleo (the development local node) shall further distribute funds to the other accounts.

### Asserter

```zsh
leo account new 
```
we get
```
  Private Key  APrivateKey1zkpBowzLhiXXTaiUwcdCGNTe2G4CCsHN4qSeaw9Z5DNNrv6
     View Key  AViewKey1u4CUGNnSrq712SxfyWbnC1NswY2PjhGUzvmQProWRzeC
      Address  aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca
```

### Disputer

```zsh
leo account new 
```
we get
```
  Private Key  APrivateKey1zkpFD3KggYarteFMYhRtQt9213yFYJgAgRL1Tcbxb58AQwt
     View Key  AViewKey1dPzSsyswGjFXPNqeAeCtzXxpELUt7PZo7gsmxKjDt2q6
      Address  aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52
```

### Voters

#### Voter 1

```zsh
leo account new 
```
we get
```
  Private Key  APrivateKey1zkp3UiRhixB2D1UJ8FhoSvGR9Ux6Fx9n4cgMMQqx8sx6Zg5
     View Key  AViewKey1qmZuCwmLutGLd53yM9MjEyzA2FNVZ3rAnJB18adq9MCv
      Address  aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw
```

#### Voter 2

```zsh
leo account new 
```
we get
```
  Private Key  APrivateKey1zkpGUXMJtMzYWVJSSmXqEJ6pcAYYwWoNfJyVXCUR4arNpfT
     View Key  AViewKey1r8HJNQPV5wECsNyd5H5q5qqa3wSAQq3gKQN7H7q576Gx
      Address  aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6
```

#### Voter 3

```zsh
leo account new 
```
we get
```
  Private Key  APrivateKey1zkp5LGHwewLv4QW1ah9zUrGcwekRGcGYDBHaAXLkjokygLE
     View Key  AViewKey1mT7MS2Hb2LSppmVbUQ87uB4G1BKxoWZpaUk6tUAr5hpk
      Address  aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah
```

## Calling Workflow

### Install

Install the program dark_optimistic_oracle.aleo and its dependencies:
```zsh
./install.sh
```

### Fund the accounts

We will not use relayers for this demo. Each account will broadcast its own calls.
For that, each account will need some Aleo credits, and some DOOR tokens.

We can see how much the Owner account has in Aleo credits:
```zsh
leo query program credits.aleo --mapping-value account $PROTOCOL
```

and how much in DOOR tokens (from the `cli` folder):
```zsh
./authorized_balance.sh $PROTOCOL 
```

Let's give one Aleo credit to each of the participants' accounts (from the top folder):
```zsh
leo execute transfer_public $ASSERTER 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public $DISPUTER 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public $VOTER_1 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public $VOTER_2 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public $VOTER_3 1_000_000u64 --program credits.aleo --broadcast --yes
```
as well as DOOR tokens. The Asserter and Disputer need 100 public DOOR balance (from the top folder):
```zsh
. ./.env
leo execute transfer_public $DOOR $ASSERTER 100_000_000u128 --program token_registry.aleo  --broadcast --yes
leo execute transfer_public $DOOR $DISPUTER 100_000_000u128 --program token_registry.aleo  --broadcast --yes
```
while the voters will get 1 private DOOR balance. For Voter 1 (from the top folder):
```zsh
. ./.env
leo execute transfer_public_to_private $DOOR $VOTER_1 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_1_PK --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 3121330588734609871748391708274900086282788851325218158600396613676960313472group.public}
```
for Voter 2  (from the top folder):
```zsh
leo execute transfer_public_to_private $DOOR $VOTER_2 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_2_PK --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 2962399841561112017937952148222288338373317184206164038387692336673593229523group.public}
```
and for Voter 3  (from the top folder):
```
leo execute transfer_public_to_private $DOOR $VOTER_3 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 551272804954095516909225178664851008670266548601865780905841470616282619235group.public}
```

### Create an assertion

The Asserter creates an assertion (from the `cli` folder):
```zsh
./assertion.sh --private-key $ASSERTER_PK 123field 456field 789field 100_000_000u128 1_000_000u128 10000 20000
```

### Dispute the assertion

Before the deadline to dispute, the Disputer can dispute the above assertion (from the `cli` folder):
```zsh
./dispute.sh --private-key $DISPUTER_PK 123field 100_000_000u128
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
./voting_right.sh --private-key $VOTER_1_PK\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 3121330588734609871748391708274900086282788851325218158600396613676960313472group.public}"\
  123field 1_000_000u128
```
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  _nonce: 4201857750667438525057130336769790103361750200882561369027427376688175005097group.public}
```

Voter 2 can first pay to obtain a voting right (from the `cli` folder):
```zsh
./voting_right.sh --private-key $VOTER_2_PK\
  "{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 2962399841561112017937952148222288338373317184206164038387692336673593229523group.public}"\
  123field 1_000_000u128
```

and check:
```
snarkos developer scan --network 1 --private-key $VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  _nonce: 6333138485865701703454301964414862924300558173733845628826145309725067170093group.public}
```

Voter 3 can first pay to obtain a voting right (from the `cli` folder):
```zsh
./voting_right.sh --private-key $VOTER_3_PK\
  "{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 551272804954095516909225178664851008670266548601865780905841470616282619235group.public}"\
  123field 1_000_000u128
```

and check:
```
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  _nonce: 5592953958199139390592055861706805442555019116217359107379669006817086224269group.public}
```

#### Vote

Voter 1 will confirm the assertion (from the `cli` folder):
```zsh
./confirm.sh --private-key $VOTER_1_PK\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  _nonce: 4201857750667438525057130336769790103361750200882561369027427376688175005097group.public}"
```
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 431488381718330508005046931799418055365563462661083231908344157221646709934group.public}
```

Voter 2 will confirm the assertion (from the `cli` folder):
```zsh
./confirm.sh --private-key $VOTER_2_PK\
  "{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  _nonce: 6333138485865701703454301964414862924300558173733845628826145309725067170093group.public}"
```
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 8020196204436538834976184008213952140417282467884384617925299150718107814925group.public}
```

Voter 3 will deny the assertion (from the `cli` folder):
```zsh
./deny.sh --private-key $VOTER_3_PK\
  "{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  _nonce: 5592953958199139390592055861706805442555019116217359107379669006817086224269group.public}"
```
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  outcome: false.private,  _nonce: 4788777906723157356225912187595939256137597807768688906442037919943261414844group.public}
```

### See the voting result

Let's mock the block height to simulate time advance. This is only for testing purposes. In production, we would have to wait for the
dispute deadline to be reached (from the `cli` folder):
```zsh
./mock_block.sh 20000u32
```

### Asserter or Disputer collects award

Since the asserter is right, he can collect the refund (from the `cli` folder):
```zsh
./asserter_collect.sh --private-key $ASSERTER_PK\
  100_000_000u128 123field
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
  balance: 90000000u128,
  authorized_until: 4294967295u32
}
```

If the disputer were right, he would collect the refund and award (from the `cli` folder):

```zsh
./disputer_collect.sh --private-key $DISPUTER_PK\
  100_000_000u128 123field
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
./voter_collect.sh --private-key $VOTER_1_PK\
  1_010_000u128\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 431488381718330508005046931799418055365563462661083231908344157221646709934group.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields refund and voting award record:
```zsh
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1010000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 0u32.private,  _nonce: 5798728943360335703152236969328269452460062391951847919275153200815336855926group.public}
```

Voter 2 can collect (from the `cli` folder):
```zsh
./voter_collect.sh --private-key $VOTER_2_PK\
  1_010_000u128\
  "{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  assertion_id: 123field.private,  outcome: true.private,  _nonce: 8020196204436538834976184008213952140417282467884384617925299150718107814925group.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields refund and voting award record:
```zsh
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1010000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 0u32.private,  _nonce: 3991115892287010997836524660674400599054163270395757269398075570095425527037group.public}
```

Voter 3 can try to collect (from the `cli` folder):
```zsh
./voter_collect.sh --private-key $VOTER_3_PK\
  1_010_000u128\
  "{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  assertion_id: 123field.private,  outcome: false.private,  _nonce: 4788777906723157356225912187595939256137597807768688906442037919943261414844group.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
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
./voter_refund.sh --private-key $VOTER_1_PK\
  1_000_000u128\
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  assertion_id: 123field.private,  _nonce: 4201857750667438525057130336769790103361750200882561369027427376688175005097group.public}"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
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
  balance: 9999999797001000u128,
  authorized_until: 0u32
}
```
which is up by 1000u128 from the previous balance of 9999999797000000u128.
