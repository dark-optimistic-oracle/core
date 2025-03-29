#!/bin/zsh
set -e
set -x

# Run ./run_node.sh to start the node before running this script

. ./.env

pushd ../token-registry-workaround
./install.sh
popd
leo deploy --yes --path . --network $NETWORK --endpoint $ENDPOINT --private-key $PRIVATE_KEY
sleep 10
leo execute initialize --yes --local --broadcast                                                            
