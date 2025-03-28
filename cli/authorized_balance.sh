#!/bin/zsh
set -e
#set -x

cd ..
. ./.env

# Run balance_key and capture the output - remove trailing 'field' and clean whitespace
KEY=$(leo run balance_key $1 $2 | grep "field" | sed 's/•//g' | tr -d '[:space:]')
echo "Using key: $KEY"

leo query program token_registry.aleo --mappings

leo query program token_registry.aleo --mapping-value registered_tokens $1

# Use the captured key to query the balance (fixed program name format)
RESULT=$(leo query program token_registry.aleo --mapping-value authorized_balances $KEY)
echo Raw result:
echo $RESULT
RESULT=$(echo $RESULT | tail -n 2)
echo $RESULT
