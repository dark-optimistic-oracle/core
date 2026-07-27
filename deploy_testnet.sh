#!/bin/zsh
set -euo pipefail
set +x

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

RESUME=false
for argument in "$@"; do
  case "$argument" in
    --resume)
      RESUME=true
      ;;
    --help|-h)
      echo "Usage: ./deploy_testnet.sh [--resume]"
      exit 0
      ;;
    *)
      echo "Unknown option: ${argument}"
      echo "Usage: ./deploy_testnet.sh [--resume]"
      exit 2
      ;;
  esac
done

PUBLIC_ENV_FILE="${PUBLIC_ENV_FILE:-${SCRIPT_DIR}/.env.testnet}"
PRIVATE_ENV_FILE="${PRIVATE_ENV_FILE:-${SCRIPT_DIR}/.env.private}"

if [[ ! -f "$PUBLIC_ENV_FILE" ]]; then
  echo "Missing ${PUBLIC_ENV_FILE}. Copy .env.testnet.example and set the public deployment values."
  exit 1
fi
if [[ ! -f "$PRIVATE_ENV_FILE" ]]; then
  echo "Missing ${PRIVATE_ENV_FILE}. Copy .env.private.example and add the testnet key."
  exit 1
fi

set -a
. "$PUBLIC_ENV_FILE"
. "$PRIVATE_ENV_FILE"
set +a

PRIVATE_KEY="${TESTNET_PRIVATE_KEY:-}"
TESTNET_ENDPOINT="${ENDPOINT:-${TESTNET_ENDPOINT:-https://api.provable.com/v2}}"
DEVNET_ADMIN="aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px"

if [[ "${NETWORK:-}" != "testnet" || -z "$PRIVATE_KEY" || -z "${PROTOCOL:-}" ]]; then
  echo "NETWORK=testnet and PROTOCOL are required publicly; TESTNET_PRIVATE_KEY is required privately."
  exit 1
fi
if [[ "$PROTOCOL" == "$DEVNET_ADMIN" ]]; then
  echo "Refusing testnet deployment with the public local-devnet administrator."
  exit 1
fi

DERIVED_ADMIN="$(leo account import "$PRIVATE_KEY" 2>/dev/null | rg -o 'aleo1[a-z0-9]{58}' | tail -1)"
if [[ "$DERIVED_ADMIN" != "$PROTOCOL" ]]; then
  echo "TESTNET_PRIVATE_KEY does not control PROTOCOL; refusing deployment."
  exit 1
fi

DEPLOY_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/doo-core-testnet.XXXXXX")"
cleanup() {
  rm -rf "$DEPLOY_ROOT"
}
trap cleanup EXIT INT TERM

mkdir -p "$DEPLOY_ROOT/src" "$DEPLOY_ROOT/.aleo"
cp "$SCRIPT_DIR/program.json" "$DEPLOY_ROOT/program.json"
cp "$SCRIPT_DIR/src/main.leo" "$DEPLOY_ROOT/src/main.leo"
perl -0pi -e "s/\@admin\\(address\\s*=\\s*\"aleo1[a-z0-9]{58}\"\\)/\@admin(address=\"${PROTOCOL}\")/g" "$DEPLOY_ROOT/src/main.leo"
if ! rg -q "@admin\\(address=\"${PROTOCOL}\"\\)" "$DEPLOY_ROOT/src/main.leo"; then
  echo "Failed to set the secure testnet upgrade administrator."
  exit 1
fi

echo "Building dark_optimistic_oracle.aleo against canonical testnet token_registry.aleo..."
leo --home "$DEPLOY_ROOT/.aleo" build \
  --network testnet \
  --endpoint "$TESTNET_ENDPOINT" \
  --path "$DEPLOY_ROOT"

PROGRAM_ID="dark_optimistic_oracle.aleo"
program_status() {
  local response_body="$DEPLOY_ROOT/program-status.txt"
  local response_code
  response_code="$(curl -sS -o "$response_body" -w "%{http_code}" --max-time 20 \
    "${TESTNET_ENDPOINT}/testnet/program/${PROGRAM_ID}")" || {
      echo "000"
      return
    }
  if [[ "$response_code" == "404" ]]; then
    local edition_code
    local edition_value
    edition_code="$(curl -sS -o "$response_body" -w "%{http_code}" --max-time 20 \
      "${TESTNET_ENDPOINT}/testnet/program/${PROGRAM_ID}/latest_edition")" || edition_code="000"
    edition_value="$(<"$response_body")"
    if [[ "$edition_code" == "200" && "$edition_value" == <-> ]]; then
      echo "200"
      return
    fi
  fi
  echo "$response_code"
}

PROGRAM_STATUS="$(program_status)"
COMMON_ARGS=(
  --yes
  --broadcast
  --network testnet
  --endpoint "$TESTNET_ENDPOINT"
  --private-key "$PRIVATE_KEY"
  --network-retries 5
  --max-wait 30
  --blocks-to-check 100
  --home "$DEPLOY_ROOT/.aleo"
)

run_checked() {
  local step_name="$1"
  local success_marker="$2"
  local expected_transaction_type="$3"
  shift 3
  local output
  local exit_code
  local transaction_id
  local transaction_body
  local attempt=1
  local verification_attempt
  while true; do
    set +e
    output="$("$@" 2>&1)"
    exit_code=$?
    set -e
    if (( exit_code != 0 && attempt < 3 )) &&
      [[ "$output" == *"/stateRoot/latest"* ]] &&
      [[ "$output" == *"Failed to fetch"* ]] &&
      [[ "$output" != *"Broadcasted transaction"* ]]; then
      echo "${step_name} hit a transient state-root fetch failure; retrying ($((attempt + 1))/3)."
      attempt=$((attempt + 1))
      sleep 2
      continue
    fi
    break
  done
  printf '%s\n' "$output" |
    sed -E 's/APrivateKey1[[:alnum:]]+/[REDACTED]/g'
  if (( exit_code == 0 )) &&
    [[ "$output" != *"Could not find the transaction."* ]] &&
    [[ "$output" == *"$success_marker"* ]]; then
    echo "${step_name} confirmed."
    return
  fi

  transaction_id="$(
    printf '%s\n' "$output" |
      rg -o 'at1[a-z0-9]+' |
      head -1 ||
      true
  )"
  if [[ -n "$transaction_id" ]]; then
    transaction_body=""
    for verification_attempt in {1..15}; do
      transaction_body="$(
        curl -fsS "${TESTNET_ENDPOINT}/testnet/transaction/${transaction_id}" ||
          true
      )"
      if [[ "$transaction_body" == *"\"type\": \"${expected_transaction_type}\""* ]]; then
        break
      fi
      sleep 2
    done
  else
    transaction_body=""
  fi
  if [[ "$transaction_body" == *"\"type\": \"${expected_transaction_type}\""* ]]; then
    echo "${step_name} verified through the accepted transaction endpoint (${transaction_id})."
    return
  fi

  echo "${step_name} failed (exit ${exit_code}); no accepted ${expected_transaction_type} transaction was found."
  exit 1
}

if [[ "$PROGRAM_STATUS" == "200" ]]; then
  if [[ "$RESUME" == "true" ]]; then
    echo "Program already exists on testnet; --resume skips an unnecessary upgrade."
  else
    echo "Program already exists on testnet; broadcasting an administrator-authorized upgrade."
    run_checked "Upgrade" "Upgrade confirmed!" deploy \
      leo upgrade "${COMMON_ARGS[@]}" --path "$DEPLOY_ROOT" --skip token_registry.aleo
  fi
elif [[ "$PROGRAM_STATUS" == "404" ]]; then
  echo "Program is not deployed; broadcasting the initial deployment."
  run_checked "Deploy" "Deployment confirmed!" deploy \
    leo deploy "${COMMON_ARGS[@]}" --path "$DEPLOY_ROOT" --skip token_registry.aleo
else
  echo "Unable to determine testnet program state (HTTP ${PROGRAM_STATUS})."
  exit 1
fi

FEE_COLLECTOR="$(
  curl -fsS \
    "${TESTNET_ENDPOINT}/testnet/program/dark_optimistic_oracle.aleo/mapping/fee_collector/0u8" ||
    true
)"
if [[ -z "$FEE_COLLECTOR" || "$FEE_COLLECTOR" == "null" || "$FEE_COLLECTOR" == '"null"' ]]; then
  echo "Initializing the DOOR token in canonical token_registry.aleo..."
  run_checked "Initialize" "Execution confirmed!" execute \
    leo execute "${PROGRAM_ID}::initialize" "${COMMON_ARGS[@]}" --no-local
else
  echo "dark_optimistic_oracle.aleo is already initialized; skipping initialize."
fi

echo "Testnet deployment completed."
