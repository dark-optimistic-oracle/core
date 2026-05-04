#!/bin/zsh
set -e
# set -x

# Help message
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0"
    exit 0
fi

cd ..
. ./.env

# Extract the last field literal from leo output.
RESULT=$(leo run get_token_id 2>&1 | grep -Eo '[0-9]+field' | tail -n 1)
if [[ -z "$RESULT" ]]; then
    echo "ERROR: Could not extract token id from leo run get_token_id output."
    exit 1
fi
echo "$RESULT"
