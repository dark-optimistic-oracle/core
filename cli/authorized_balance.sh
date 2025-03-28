#!/bin/zsh
set -e
#set -x

# Help message
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [token_id] address"
    echo "  token_id: (optional) The token ID field value"
    echo "  address:  The Aleo address to check balance for"
    exit 0
fi

# Parameter validation
if [[ $# -eq 0 ]] || [[ $# -gt 2 ]]; then
    echo "Error: Invalid number of parameters"
    echo "Use --help for usage information"
    exit 1
fi

# Set token_id and address based on number of parameters
if [[ $# -eq 1 ]]; then
    TOKEN_ID="17235612283251326583536974293363256992451820371731919189503231730609724436387field"
    ADDRESS="$1"
else
    TOKEN_ID="$1"
    ADDRESS="$2"
fi

cd ..
. ./.env

# Run balance_key and capture the output - remove trailing 'field' and clean whitespace
KEY=$(leo run balance_key $TOKEN_ID $ADDRESS | grep "field" | sed 's/•//g' | tr -d '[:space:]')
# echo "Using key: $KEY"

# Use the captured key to query the balance (fixed program name format)
RESULT=$(leo query program token_registry.aleo --mapping-value authorized_balances $KEY)
RESULT=$(echo "$RESULT" | grep -A 999 "Successfully" | tail -n +3)
echo "$RESULT"
