#!/bin/zsh
set -e
#set -x

cd ..
. ./.env

# Function to get the current block height
get_current_block_height() {
    BLOCK_HEIGHT=$(leo query block --latest-height)
    echo $(echo $BLOCK_HEIGHT | grep -oE '[0-9]+$')
}

# Function to get the current address
get_current_address() {
    PRIVATE_KEY=${PRIVATE_KEY:?Error: PRIVATE_KEY is not set in the environment.}
    ADDRESS=$(leo account import $PRIVATE_KEY | grep -oE 'aleo1[a-z0-9]+$')
    echo $ADDRESS
}

# Function to advance the block
advance_block() {
    CURRENT_ADDRESS=$1
    sleep 1
    # leo execute transfer_public $CURRENT_ADDRESS 0u64 --program credits.aleo --broadcast --yes > /dev/null 2>&1
}

# Help switch: Display usage instructions
if [[ $# -eq 1 ]] && ([[ $1 == "-h" ]] || [[ $1 == "--help" ]]); then
    echo "Usage:"
    echo "  $0                              # Show the current block height"
    echo "  $0 <block_number>               # Advance to the specified block height"
    echo "  $0 -r | --relative <count>      # Advance by a relative number of blocks"
    echo "  $0 -h | --help                  # Display this help message"
    exit 0
fi

# No parameters: Show the current block height
if [[ $# -eq 0 ]]; then
    CURRENT_BLOCK=$(get_current_block_height)
    echo "Current block height: $CURRENT_BLOCK"
    exit 0
fi

# Start timing for commands with parameters
START_TIME=$(date +%s)

# One parameter: Advance to the specified block height
if [[ $# -eq 1 ]]; then
    TARGET_BLOCK=$1
    CURRENT_BLOCK=$(get_current_block_height)

    if [[ $TARGET_BLOCK -le $CURRENT_BLOCK ]]; then
        echo "Error: Target block ($TARGET_BLOCK) is less than or equal to the current block ($CURRENT_BLOCK)."
        exit 1
    fi

    CURRENT_ADDRESS=$(get_current_address)
    echo -ne "\rCurrent block: $CURRENT_BLOCK"
    while [[ $CURRENT_BLOCK -lt $TARGET_BLOCK ]]; do
        advance_block $CURRENT_ADDRESS
        CURRENT_BLOCK=$(get_current_block_height)
        echo -ne "\rCurrent block: $CURRENT_BLOCK"
    done
    echo # Print a newline after the final block height
    END_TIME=$(date +%s)
    echo "Execution time: $((END_TIME - START_TIME)) seconds"
    exit 0
fi

# Two parameters: Advance by a relative number of blocks
if [[ $# -eq 2 ]] && ([[ $1 == "-r" ]] || [[ $1 == "--relative" ]]); then
    RELATIVE_BLOCKS=$2
    if ! [[ $RELATIVE_BLOCKS =~ ^[0-9]+$ ]]; then
        echo "Error: Relative block count must be a positive integer."
        exit 1
    fi

    CURRENT_BLOCK=$(get_current_block_height)
    TARGET_BLOCK=$((CURRENT_BLOCK + RELATIVE_BLOCKS))
    CURRENT_ADDRESS=$(get_current_address)

    echo -ne "\rCurrent block: $CURRENT_BLOCK"
    while [[ $CURRENT_BLOCK -lt $TARGET_BLOCK ]]; do
        advance_block $CURRENT_ADDRESS
        CURRENT_BLOCK=$(get_current_block_height)
        echo -ne "\rCurrent block: $CURRENT_BLOCK"
    done
    echo # Print a newline after the final block height
    END_TIME=$(date +%s)
    echo "Execution time: $((END_TIME - START_TIME)) seconds"
    exit 0
fi

# Invalid usage
echo "Usage:"
echo "  $0                 # Show the current block height"
echo "  $0 <block_number>  # Advance to the specified block height"
echo "  $0 -r <count>      # Advance by a relative number of blocks"
echo "  $0 -h | --help     # Display this help message"
exit 1
