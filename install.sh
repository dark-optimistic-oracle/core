#!/bin/zsh
set -euo pipefail
set +x

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

if [[ ! -f .env || ! -f .env.private ]]; then
  echo "Missing .env or .env.private. Copy the example files first."
  exit 1
fi

. ./.env
. ./.env.private
PRIVATE_KEY="${DEVNET_PRIVATE_KEY:-}"
API_NETWORK="${API_NETWORK:-${NETWORK:-testnet}}"

if [[ -z "${NETWORK:-}" || -z "${ENDPOINT:-}" || -z "$PRIVATE_KEY" ]]; then
  echo "Missing required public settings in .env or DEVNET_PRIVATE_KEY in .env.private."
  exit 1
fi

# Keep this aligned with run_node.sh local devnet consensus heights.
CONSENSUS_HEIGHTS="${CONSENSUS_HEIGHTS:-0,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20}"

run_leo_checked() {
  local step="$1"
  local success_marker="$2"
  local expected_transaction_type="$3"
  shift 3

  local output
  local exit_code
  local transaction_id
  local transaction_body
  set +e
  output="$("$@" 2>&1)"
  exit_code=$?
  set -e

  printf '%s\n' "$output" |
    sed -E 's/APrivateKey1[[:alnum:]]+/[REDACTED]/g'

  if (( exit_code == 0 )) &&
    [[ "$output" != *"Could not find the transaction."* ]] &&
    [[ "$output" == *"$success_marker"* ]]; then
    echo "${step} confirmed."
    return
  fi

  transaction_id="$(
    printf '%s\n' "$output" |
      rg -o 'at1[a-z0-9]+' |
      head -1 ||
      true
  )"
  if [[ -n "$transaction_id" ]]; then
    transaction_body="$(
      curl -fsS "${ENDPOINT}/${API_NETWORK}/transaction/${transaction_id}" ||
        true
    )"
  else
    transaction_body=""
  fi
  if [[ "$transaction_body" == *"\"type\": \"${expected_transaction_type}\""* ]]; then
    echo "${step} verified through the accepted transaction endpoint (${transaction_id})."
    return
  fi

  echo "ERROR: ${step} failed (exit ${exit_code}); no accepted ${expected_transaction_type} transaction was found."
  exit 1
}

program_status() {
  local response_file
  local response_code
  response_file="$(mktemp "${TMPDIR:-/tmp}/doo-oracle-status.XXXXXX")"
  response_code="$(
    curl -sS -o "$response_file" -w '%{http_code}' --max-time 20 \
      "${ENDPOINT}/${API_NETWORK}/program/dark_optimistic_oracle.aleo"
  )" || response_code="000"
  if [[ "$response_code" == "500" ]] &&
    rg -q 'Missing program for ID dark_optimistic_oracle.aleo' "$response_file"; then
    response_code="404"
  fi
  rm -f "$response_file"
  echo "$response_code"
}

common_args=(
  --yes
  --path .
  --devnet
  --broadcast
  --endpoint "$ENDPOINT"
  --private-key "$PRIVATE_KEY"
  --consensus-heights "$CONSENSUS_HEIGHTS"
  --max-wait 20
  --blocks-to-check 100
)

echo "Using endpoint: $ENDPOINT"
echo "Consensus heights: $CONSENSUS_HEIGHTS"

echo "[1/4] install or upgrade token registry dependency"
"$SCRIPT_DIR/../token-registry-workaround/install.sh"

echo "[2/4] leo clean and build"
leo clean
leo build

program_http_code="$(program_status)"
if [[ "$program_http_code" == "200" ]]; then
  echo "[3/4] upgrade dark_optimistic_oracle.aleo"
  run_leo_checked \
    "upgrade" \
    "Upgrade confirmed!" \
    deploy \
    leo upgrade "${common_args[@]}"
elif [[ "$program_http_code" == "404" ]]; then
  echo "[3/4] deploy dark_optimistic_oracle.aleo"
  run_leo_checked \
    "deploy" \
    "Deployment confirmed!" \
    deploy \
    leo deploy "${common_args[@]}"
else
  echo "Unable to determine dark_optimistic_oracle.aleo state (HTTP ${program_http_code})."
  exit 1
fi

fee_collector="$(
  curl -fsS \
    "${ENDPOINT}/${API_NETWORK}/program/dark_optimistic_oracle.aleo/mapping/fee_collector/0u8" ||
    true
)"
if [[ -z "$fee_collector" || "$fee_collector" == "null" || "$fee_collector" == '"null"' ]]; then
  echo "[4/4] initialize dark_optimistic_oracle.aleo"
  run_leo_checked \
    "initialize" \
    "Execution confirmed!" \
    execute \
    leo execute initialize "${common_args[@]}"
else
  echo "[4/4] dark_optimistic_oracle.aleo is already initialized; skipping initialize."
fi

echo "Install or upgrade completed successfully."
