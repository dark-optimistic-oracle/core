#!/bin/zsh
set -e
#set -x

cd ..
. ./.env

# Convert NETWORK parameter from .env
if [[ "$NETWORK" == "mainnet" ]]; then
    NETWORK_ID=0
elif [[ "$NETWORK" == "testnet" ]]; then
    NETWORK_ID=1
else
    echo "Error: Unsupported NETWORK value in .env. Must be 'mainnet' or 'testnet'."
    exit 1
fi

# Help message
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [--private-key <key>] <cost> <id>"
    echo "  --private-key: Optional private key for signing (string)"
    echo "  cost: The anticipated cost of the assertion (in DOOR tokens) (u128)"
    echo "  id: The ID of the assertion (field)"
    exit 0
fi

# Parse optional --private-key parameter
if [[ "$1" == "--private-key" ]]; then
    PRIVATE_KEY=$2
    shift 2
fi

# Parameter validation
if [[ $# -eq 0 ]] || [[ $# -gt 4 ]]; then
    echo "Error: Invalid number of parameters"
    echo "Use --help for usage information"
    exit 1
fi

# snarkos developer execute\
#     --network $NETWORK_ID --query $ENDPOINT --broadcast $ENDPOINT --private-key $PRIVATE_KEY\
# snarkos developer execute\
#     --network $NETWORK_ID --query $ENDPOINT --dry-run --private-key $PRIVATE_KEY\
#     dark_optimistic_oracle.aleo collect_dispute_award\
#     $1 $2
leo execute --private-key $PRIVATE_KEY --yes --local --broadcast\
    collect_dispute_award $1 $2