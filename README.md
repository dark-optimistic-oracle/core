#Dark Optimistic Oracle core contracts

## How to deploy and run locally

In one zsh terminal run the following:
```zsh
amareleo-chain start
```

To compile:
```zsh
leo build
```

To run without executing:
```zsh
leo run "main" "1u32" "2u32"
```

To deploy:
```zsh
leo deploy
```
and answer "y" to the question:
```
Do you want to submit deployment of program `dark_optimistic_oracle.aleo` to network testnet via endpoint http://localhost:3030 using address aleo1rhgdu77hgyqd3xjj8u
```

To run and broadcast to the local blockchain:
```zsh
leo execute "main" "1u32" "2u32" --broadcast --local
```

oro"

```zsh
leo execute "main" "1u32" "2u32" --broadcast --program "dark_optimistic_oracle.aleo"
```
