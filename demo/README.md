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
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 2844964691049150336816418698272453117737065199382451050143897709194254851008group.public}
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
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 6469263839186893216716018505128292796801782977677577314369432707056710293830group.public}
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
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 5435035154732887285519184900581219846165669191489774863943030320053394312647group.public}
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
  "{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 2844964691049150336816418698272453117737065199382451050143897709194254851008group.public}"\
  123field 1_000_000u128
```
# ERROR: Status code 500
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
```

Voter 2 can first pay to obtain a voting right (from the `cli` folder):
```zsh
./voting_right.sh --private-key $VOTER_2_PK\
  "<payment>"\
  123field 1_000_000u128
```

and check:
```
snarkos developer scan --network 1 --private-key $VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
```

Voter 3 can first pay to obtain a voting right (from the `cli` folder):
```zsh
./voting_right.sh --private-key $VOTER_3_PK\
  "<payment>"\
  123field 1_000_000u128
```

and check:
```
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingRight record:
```
```

#### Vote

Voter 1 will confirm the assertion (from the `cli` folder):
```zsh
./confirm.sh --private-key $VOTER_1_PK\
  "<voting_right>"
```
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
```

Voter 2 will confirm the assertion (from the `cli` folder):
```zsh
./confirm.sh --private-key $VOTER_2_PK\
  "<voting_right>"
```
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
```

Voter 3 will deny the assertion (from the `cli` folder):
```zsh
./deny.sh --private-key $VOTER_3_PK\
  "<voting_right>"
```
and check:
```
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields a the VotingReceipt record:
```
```

### See the voting result

Let's mock the block height to simulate time advance. This is only for testing purposes. In production, we would have to wait for the
dispute deadline to be reached (from the `cli` folder):
```zsh
./mock_block.sh 20000
```

### Asserter or Disputer collects award

Since the asserter is right, he can collect the refund (from the `cli` folder):
```zsh
./asserter_collect.sh --private-key $ASSERTER_PK\
  100_000_000u128 123field
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $ASSERTER_PK --endpoint $ENDPOINT --last 10
```
which yields the refund record:
```zsh
```

If the disputer were right, he would collect the refund and award (from the `cli` folder):

```zsh
./disputer_collect.sh --private-key $DISPUTER_PK\
  100_000_000u128 123field
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $DISPUTER_PK --endpoint $ENDPOINT --last 10
```
which should yields the refund record, but this time the transaction would fail as the disputer was not right and obtain nothing:
```zsh
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
  "<voting_receipt>"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_1_PK --endpoint $ENDPOINT --last 10
```
which yields refund and voting award record:
```zsh
```

Voter 2 can collect (from the `cli` folder):
```zsh
./voter_collect.sh --private-key $VOTER_2_PK\
  1_010_000u128\
  "<voting_receipt>"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_2_PK --endpoint $ENDPOINT --last 10
```
which yields refund and voting award record:
```zsh
```

Voter 3 can try to collect (from the `cli` folder):
```zsh
./voter_collect.sh --private-key $VOTER_3_PK\
  1_010_000u128\
  "<voting_receipt>"
```
and check:
```zsh
snarkos developer scan --network 1 --private-key $VOTER_3_PK --endpoint $ENDPOINT --last 10
```
which yields nothing for refund and voting award, because of the incorrect voting - he got slashed:
```zsh
```

#### Get Refund for unused Voting Right

If the voter did not vote on time they can get a refund for the VotingRight (from the `cli` folder):
```zsh
./voter_refund.sh --private-key $VOTER_1_PK\
  1_000_000u128\
  "<voting_receipt>"
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
```

