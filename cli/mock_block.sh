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

get_current_mock_block_height() {
    MOCK=$(leo query program dark_optimistic_oracle.aleo --mapping-value current_mock_block_height 0u8)
    if [[ "$MOCK" == *"null"* ]]; then
        echo 0
    else
        echo $(echo $MOCK | grep -oE '^[0-9]+')
    fi
}

# Help message
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [<blocks>]"
    echo "  blocks: Optional number of block to mock forward (u32). If not provided, displays the current mock block number."
    exit 0
fi

# Parameter validation
if [[ $# -gt 1 ]]; then
    echo "Error: Invalid number of parameters"
    echo "Use --help for usage information"
    exit 1
fi

# No parameters: Show the current mocked block height
if [[ $# -eq 0 ]]; then
    CURRENT_BLOCK=$(get_current_block_height)
    CURRENT_MOCK_BLOCK_HEIGHT=$(get_current_mock_block_height)
    echo "Current block height: $CURRENT_BLOCK"
    echo "Current mock block height: $CURRENT_MOCK_BLOCK_HEIGHT"
    echo "Mocked block height: $((CURRENT_MOCK_BLOCK_HEIGHT + CURRENT_BLOCK))"
    exit 0
fi

# One parameter: set the new mocking value
if [[ $# -eq 1 ]]; then
    leo execute mock_block_height $1 --yes --local --broadcast                                                            
    exit 0
fi