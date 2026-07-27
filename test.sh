#!/bin/zsh
set -euo pipefail
set +x

SCRIPT_DIR="${0:A:h}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/doo-core-tests.XXXXXX")"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

mkdir -p \
    "$TEST_ROOT/oracle/src" \
    "$TEST_ROOT/oracle/tests" \
    "$TEST_ROOT/token-registry-workaround/src" \
    "$TEST_ROOT/.aleo"

cp "$SCRIPT_DIR/src/main.leo" "$TEST_ROOT/oracle/src/main.leo"
cp "$SCRIPT_DIR/tests/test_oracle.leo" "$TEST_ROOT/oracle/tests/test_oracle.leo"
cp "$SCRIPT_DIR/tests/program.local.json" "$TEST_ROOT/oracle/program.json"
cp "$SCRIPT_DIR/../token-registry-workaround/program.json" "$TEST_ROOT/token-registry-workaround/program.json"
cp "$SCRIPT_DIR/../token-registry-workaround/src/main.leo" "$TEST_ROOT/token-registry-workaround/src/main.leo"

leo -q \
    --home "$TEST_ROOT/.aleo" \
    test \
    --network testnet \
    --endpoint "${ALEO_TEST_ENDPOINT:-https://api.explorer.provable.com/v2}" \
    --path "$TEST_ROOT/oracle"

echo "All core Leo unit tests passed."
