#!/bin/zsh
set -e
set -x

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
    echo "Usage: $0 [--private-key <key>] <id> <title> <content_hash> <cost> <voter_fee> <dispute_deadline_blocks> <voting_deadline_blocks>"
    echo "  --private-key: Optional private key for signing (string)"
    echo "  id: The ID of the assertion (field)"
    echo "  title: The title of the assertion (field)"
    echo "  content_hash: The hash of the content being asserted (field)"
    echo "  cost: The cost of the assertion (in DOOR tokens) (u128)"
    echo "  voter_fee: The fee for voters (in DOOR tokens) (u128)"
    echo "  dispute_deadline_blocks: The number of blocks before the dispute deadline (u32)"
    echo "  voting_deadline_blocks: The number of blocks before the voting deadline (u32)"
    exit 0
fi

# Parse optional --private-key parameter
if [[ "$1" == "--private-key" ]]; then
    PRIVATE_KEY=$2
    shift 2
fi

# Parameter validation
if [[ $# -eq 0 ]] || [[ $# -gt 9 ]]; then
    echo "Error: Invalid number of parameters"
    echo "Use --help for usage information"
    exit 1
fi

# Get the latest block height
BLOCK_HEIGHT=$(leo query block --latest-height)
BLOCK_HEIGHT=$(echo $BLOCK_HEIGHT | grep -oE '[0-9]+$')

# Add the BLOCK_HEIGHT to the dispute and voting deadline parameters
DISPUTE_DEADLINE_BLOCKS=$((BLOCK_HEIGHT + $6))
VOTING_DEADLINE_BLOCKS=$((BLOCK_HEIGHT + $7))

# snarkos developer execute\
#     --network $NETWORK_ID --query $ENDPOINT --dry-run --private-key $PRIVATE_KEY\
# snarkos developer execute\
#     --network $NETWORK_ID --query $ENDPOINT --broadcast $ENDPOINT --private-key $PRIVATE_KEY\
#     dark_optimistic_oracle.aleo create_assertion\
#     "{ id: $1, title: $2, content_hash: $3, cost: $4, voter_fee: $5, dispute_deadline_block_height: ${DISPUTE_DEADLINE_BLOCKS}u32, voting_deadline_block_height: ${VOTING_DEADLINE_BLOCKS}u32 }"
leo execute --private-key $PRIVATE_KEY --yes --local --broadcast\
    create_assertion\
    "{ id: $1, title: $2, content_hash: $3, cost: $4, voter_fee: $5, dispute_deadline_block_height: ${DISPUTE_DEADLINE_BLOCKS}u32, voting_deadline_block_height: ${VOTING_DEADLINE_BLOCKS}u32 }"
