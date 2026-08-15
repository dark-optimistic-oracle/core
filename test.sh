#!/bin/zsh
set -euo pipefail
set +x

LEO_BIN="${LEO_BIN:-leo}"
if ! command -v "$LEO_BIN" >/dev/null 2>&1; then
    echo "Leo is required. Install Leo 4.4.1 or set LEO_BIN to that binary."
    exit 1
fi
LEO_VERSION="$("$LEO_BIN" --version 2>/dev/null | rg -o '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
if [[ "$LEO_VERSION" != "4.4.1" ]]; then
    echo "Leo 4.4.1 is required for the current program manifest; found ${LEO_VERSION:-unknown}."
    exit 1
fi

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

"$LEO_BIN" -q \
    --home "$TEST_ROOT/.aleo" \
    test \
    --network testnet \
    --endpoint "${ALEO_TEST_ENDPOINT:-https://api.provable.com/v2}" \
    --path "$TEST_ROOT/oracle"

echo "All core Leo unit tests passed."
