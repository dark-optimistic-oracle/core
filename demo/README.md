# Demo

The full workflow of the protocol is described and tried.

## Accounts and Roles

Let's set up several roles and accounts for them:

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
leo query program credits.aleo --mapping-value account aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px
```

and how much in DOOR tokens (from the `cli` folder):
```zsh
./authorized_balance.sh aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px 
```

Let's give one Aleo credit to each of the participants' accounts (from the top folder):
```zsh
leo execute transfer_public aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6 1_000_000u64 --program credits.aleo --broadcast --yes
leo execute transfer_public aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah 1_000_000u64 --program credits.aleo --broadcast --yes
```
as well as DOOR tokens. The Asserter and Disputer need 100 public DOOR balance (from the top folder):
```zsh
. ./.env
leo execute transfer_public $DOOR aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca 100_000_000u128 --program token_registry.aleo  --broadcast --yes
leo execute transfer_public $DOOR aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52 100_000_000u128 --program token_registry.aleo  --broadcast --yes
```
while the voters will get 1 private DOOR balance. For Voter 1 (from the top folder):
```zsh
. ./.env
leo execute transfer_public_to_private $DOOR aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key APrivateKey1zkp3UiRhixB2D1UJ8FhoSvGR9Ux6Fx9n4cgMMQqx8sx6Zg5 --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 3662617502716024984191204143354475946135360656935981529602732280610362138649group.public}
```
for Voter 2  (from the top folder):
```zsh
leo execute transfer_public_to_private $DOOR aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key APrivateKey1zkpGUXMJtMzYWVJSSmXqEJ6pcAYYwWoNfJyVXCUR4arNpfT --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 7436919775129778827797110222871323145238176154282216336930881428798799390657group.public}
```
and for Voter 2  (from the top folder):
```
leo execute transfer_public_to_private $DOOR aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
To see this record:
```zsh
snarkos developer scan --network 1 --private-key APrivateKey1zkp5LGHwewLv4QW1ah9zUrGcwekRGcGYDBHaAXLkjokygLE --endpoint $ENDPOINT --last 10
```
showing the record:
```
{  owner: aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah.private,  amount: 1000000u128.private,  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,  external_authorization_required: false.private,  authorized_until: 4294967295u32.private,  _nonce: 8419915732726617122985977566115675398832330706414534111397402875417465794465group.public}
```

### Create an assertion

The Asserter creates an assertion (from the `cli` folder):
```zsh
./assertion.sh --private-key APrivateKey1zkpBowzLhiXXTaiUwcdCGNTe2G4CCsHN4qSeaw9Z5DNNrv6 123field 456field 789field 100_000_000u128 1_000_000u128 3 10
```

### Dispute the assertion

Before the deadline to dispute, the Disputer can dispute the above assertion:
```zsh
./dispute.sh --private-key APrivateKey1zkpFD3KggYarteFMYhRtQt9213yFYJgAgRL1Tcbxb58AQwt 123field 100_000_000u128
```

### Vote on the assertion

Each voter has to execute the following steps:
- Purchase a Voting Right
- Vote (either Confirm or Deny)
- Collect the voting award
- Get refund for the Voting Right in case it was not used (did not vote) by the deadline

#### Purchase Voting Right

Voter 1 can first pay to obtain a voting right:
```zsh
./voting_right.sh --private-key APrivateKey1zkp3UiRhixB2D1UJ8FhoSvGR9Ux6Fx9n4cgMMQqx8sx6Zg5\
  "{\
    owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,\
    amount: 1_000_000u128.private,\
    token_id: ${DOOR}.private,\
    external_authorization_required: false.private,\
    authorized_until: 0u32.private,\
    _nonce: 8419915732726617122985977566115675398832330706414534111397402875417465794465group.public\
  }"\
  123field 1_000_000u128
```

#### Vote

To confirm the assertion:
```zsh
./confirm.sh --private-key APrivateKey1zkp3UiRhixB2D1UJ8FhoSvGR9Ux6Fx9n4cgMMQqx8sx6Zg5\
  "{\
    owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,\
    assertion_id: 123field.private,\
    _nonce: 8419915732726617122985977566115675398832330706414534111397402875417465794465group.public\
  }"
```

To deny the assertion:
```zsh
./deny.sh --private-key APrivateKey1zkp3UiRhixB2D1UJ8FhoSvGR9Ux6Fx9n4cgMMQqx8sx6Zg5\
  "{\
    owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,\
    assertion_id: 123field.private,\
    _nonce: 8419915732726617122985977566115675398832330706414534111397402875417465794465group.public\
  }"
```

### See the voting result

### Asserter or Disputer collects award

### Voter collect awards

The voter can either collect the award for timely correct voting or get a refund for the Voting Right that was not used.

#### Collect voting award

If the Voter voted on time, they can collect the award for the correct voting. If the vote was not correct
there is nothing to collect, so the collection would yield a private DOOR Token in the amount of 0.

We have to pre-calculate the amount of the award, which is $1,000,000 * (100 + 1) / 100 = 1,010,000

```zsh
./voter_collect.sh --private-key APrivateKey1zkp3UiRhixB2D1UJ8FhoSvGR9Ux6Fx9n4cgMMQqx8sx6Zg5\
  1010000u128\
  "{\
    owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,\
    assertion_id: 123field.private,\
    outcome: true.private,\
    _nonce: 8419915732726617122985977566115675398832330706414534111397402875417465794465group.public\
  }"
```

#### Get Refund for unused Voting Right

If the voter did not vote on time they can get a refund for the Voting Right:

```zsh
./voter_refund.sh --private-key APrivateKey1zkp3UiRhixB2D1UJ8FhoSvGR9Ux6Fx9n4cgMMQqx8sx6Zg5\
  1000000u128\
  "{\
    owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,\
    assertion_id: 123field.private,\
    _nonce: 8419915732726617122985977566115675398832330706414534111397402875417465794465group.public\
  }"
```

### See the voting result

We can see the voting result as follows:
```zsh
leo quey program dark_optimisticOracle.aleo --mapping-values assertions 123field
```

#### Asserter collects partial refund

If the assertion is not disputed or voted as correct:

```zsh
./asserter_collect.sh --private-key APrivateKey1zkpBowzLhiXXTaiUwcdCGNTe2G4CCsHN4qSeaw9Z5DNNrv6 100_000_000u128 123field
```

#### Disputer collects refund and reward

If the assertion is disputed and voted as incorrect:

```zsh
./disputer_collect.sh --private-key APrivateKey1zkpFD3KggYarteFMYhRtQt9213yFYJgAgRL1Tcbxb58AQwt 100_000_000u128 123field
```

### Protocol collects fees

At any time the protocol can collect any part of the the fees accrued:

```zsh
./protocol_collect.sh 1_000u128
```
