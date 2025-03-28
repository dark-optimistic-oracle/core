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

# Run balance_key and capture the output - remove trailing 'field' and clean whitespace
RESULT=$(leo run get_token_id)
#echo Result:
#echo $RESULT
RESULT=$(echo $RESULT | grep -A 2 "Output" | sed '1d; s/•//g' | tr -d '[:space:]')
echo $RESULT
