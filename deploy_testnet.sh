#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

. ./.env

if [[ "${NETWORK:-}" != "testnet" || -z "${PRIVATE_KEY:-}" ]]; then
  echo "Set NETWORK=testnet and PRIVATE_KEY in .env before deploying."
  exit 1
fi

TESTNET_ENDPOINT="${TESTNET_ENDPOINT:-https://api.explorer.provable.com/v1}"
PROGRAM_URL="${TESTNET_ENDPOINT}/testnet/program/dark_optimistic_oracle.aleo"
DEVNET_ADMIN="aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px"

if rg -q "@admin\\(address=\"${DEVNET_ADMIN}\"\\)" src/main.leo; then
  echo "Refusing testnet deployment: src/main.leo still uses the public local-devnet admin."
  echo "Replace @admin with a secure, user-controlled testnet address first."
  exit 1
fi

if [[ "${PROTOCOL:-}" == "$DEVNET_ADMIN" ]]; then
  echo "Refusing testnet deployment: .env still selects the public local-devnet account."
  exit 1
fi

echo "Building dark_optimistic_oracle.aleo against the canonical testnet token_registry.aleo..."
leo clean
leo build --network testnet --endpoint "$TESTNET_ENDPOINT"

PROGRAM_STATUS="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 20 "$PROGRAM_URL")"

if [[ "$PROGRAM_STATUS" == "200" ]]; then
  echo "Program already exists on testnet; broadcasting an admin-authorized upgrade."
  leo upgrade \
    --yes \
    --broadcast \
    --network testnet \
    --endpoint "$TESTNET_ENDPOINT" \
    --network-retries 5 \
    --max-wait 30 \
    --blocks-to-check 100
elif [[ "$PROGRAM_STATUS" == "404" ]]; then
  echo "Program is not deployed; broadcasting the initial deployment."
  leo deploy \
    --yes \
    --broadcast \
    --network testnet \
    --endpoint "$TESTNET_ENDPOINT" \
    --network-retries 5 \
    --max-wait 30 \
    --blocks-to-check 100

  echo "Initializing the DOOR token in the canonical testnet registry..."
  leo execute initialize \
    --yes \
    --broadcast \
    --network testnet \
    --endpoint "$TESTNET_ENDPOINT" \
    --network-retries 5 \
    --max-wait 30 \
    --blocks-to-check 100
else
  echo "Unable to determine testnet program state (HTTP ${PROGRAM_STATUS})."
  exit 1
fi

echo "Testnet deployment completed."
