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
leo execute transfer_public aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca 1_000_000u64 --program credits.aleo  --broadcast --yes
leo execute transfer_public aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52 1_000_000u64 --program credits.aleo  
leo execute transfer_public aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw 1_000_000u64 --program credits.aleo  
leo execute transfer_public aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6 1_000_000u64 --program credits.aleo  
leo execute transfer_public aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah 1_000_000u64 --program credits.aleo  
```
as well as DOOR tokens. The Asserter and Disputer need 100 public DOOR balance (from the top folder):
```zsh
. ./.env
leo execute transfer_public $DOOR aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca 100_000_000u128 --program token_registry.aleo  --broadcast --yes
leo execute transfer_public $DOOR aleo1jf506dlywsr6kzxcp3spv8rnyf2sx4fstel2yezk57nchsep6yrqfu7k52 100_000_000u128 --program token_registry.aleo  --broadcast --yes
```
while the voters will get 1 private DOOR balance (from the top folder):
```zsh
. ./.env
leo run transfer_public_to_private $DOOR aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw 1_000_000u128 false --path ../token_registry_workaround --network $NETWORK
leo execute transfer_public_to_private $DOOR aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
note the resulting output records:
```
{
  owner: aleo1azkl6rf3x5t3qk48rfsprxdkx6m7e33un9qpq0aqu036rzpm9qyq596vzw.private,
  amount: 1000000u128.private,
  token_id: 346688784394585735039324415800163929700021701423791533632764818774905958305field.private,
  external_authorization_required: false.private,
  authorized_until: 4294967295u32.private,
  _nonce: 4253569419940868305251102180799951044840173323847451590038166426021035296678group.public
}
```
and for the remaining two voters (from the top folder):
```zsh
. ./.env
leo run transfer_public_to_private $DOOR aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6 1_000_000u128 false --path ../token_registry_workaround --network $NETWORK
leo execute transfer_public_to_private $DOOR aleo1u9xrpgxxf65rlp5y0czqekqte2tg5caxh3t6v5gn7jw0uex3w59sg4q5l6 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```
and
```
leo run transfer_public_to_private $DOOR aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah 1_000_000u128 false --path ../token_registry_workaround --network $NETWORK
leo execute transfer_public_to_private $DOOR aleo1p0nvzd702fha2h44zz7k48u7982mgd3sjlw2cq2ptnc32pg8dgzqc6p3ah 1_000_000u128 false --program token_registry.aleo  --broadcast --yes
```

Note that we can see the resulting records using (from the top folder):
```zsh
```

### Create an assertion

### Dispute the assertion

### Vote on the assertion

### Get the voting result

### Asserter or Disputer collects award

### Voter collect awards

### Protocol collects fees
