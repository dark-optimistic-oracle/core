#!/bin/zsh
set -e
# set -x

cd ..
. ./.env

# Run balance_key and capture the output - remove trailing 'field' and clean whitespace
RESULT=$(leo run self_address)
#echo Result:
#echo $RESULT
RESULT=$(echo $RESULT | grep -A 2 "Output" | sed '1d; s/•//g' | tr -d '[:space:]')
echo $RESULT
