#!/bin/zsh
set -euo pipefail
set +x

cd ..
. ./.env

get_current_block_height() {
    leo -q query block --latest-height
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [<blocks>]"
    echo "Without arguments, print the current local-devnet block height."
    echo "With a block count, advance the local devnode by that many real blocks."
    exit 0
fi

if [[ $# -eq 0 ]]; then
    get_current_block_height
    exit 0
fi

if [[ $# -ne 1 ]]; then
    echo "Error: expected zero or one argument."
    exit 1
fi

blocks="${1%u32}"
if ! [[ "$blocks" =~ '^[0-9]+$' ]] || [[ "$blocks" == "0" ]]; then
    echo "Error: blocks must be a positive integer."
    exit 1
fi

leo devnode advance "$blocks" --socket-addr "${ENDPOINT#http://}"
