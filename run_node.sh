#!/bin/zsh
set -e
set +x

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    . "$SCRIPT_DIR/.env"
fi
if [[ -f "$SCRIPT_DIR/.env.private" ]]; then
    . "$SCRIPT_DIR/.env.private"
fi
PRIVATE_KEY="${DEVNET_PRIVATE_KEY:-}"

show_help() {
    cat << 'EOF'
Usage: ./run_node.sh [OPTIONS]

Run a local Aleo development network node.

Options:
  --clean         Clear existing devnet storage before starting
  --install       (Re)install snarkOS at ./snarkos before starting
  --help, -h      Display this help message

Environment:
    DEVNET_STORAGE      Optional devnet storage directory (default: ./temp/devnet)
    CONSENSUS_HEIGHTS   Optional comma-separated consensus heights passed to leo devnet
                        (default for test_network: 0,5,6,...,20)
    FORCE_MINE          If "true" (default), tries to fast-forward block production while waiting

Examples:
  ./run_node.sh
  ./run_node.sh --install
  ./run_node.sh --clean
  ./run_node.sh --clean --install
EOF
}

clean=false
install=false

# Parse combinable flags.
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            show_help
            exit 0
            ;;
        --clean)
            clean=true
            ;;
        --install)
            install=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Run ./run_node.sh --help for usage."
            exit 1
            ;;
    esac
done

snarkos_path="./snarkos"
devnet_storage="${DEVNET_STORAGE:-./temp/devnet}"
default_consensus_heights="0,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20"
effective_consensus_heights="${CONSENSUS_HEIGHTS:-$default_consensus_heights}"
endpoint="${ENDPOINT:-http://localhost:3030}"
force_mine="${FORCE_MINE:-true}"

# Fail early with a clear message if install was not requested and snarkos is missing.
if [[ "$install" != "true" ]] && [[ ! -x "$snarkos_path" ]]; then
    echo "snarkOS not found or not executable at $snarkos_path"
    echo "Run ./run_node.sh --install to build it."
    exit 1
fi

cmd=(
    leo devnet --yes
    --storage "$devnet_storage"
    --snarkos "$snarkos_path"
    --snarkos-features test_network
)

cmd+=(--consensus-heights "$effective_consensus_heights")

if [[ "$install" == "true" ]]; then
    cmd+=(--install)
fi

if [[ "$clean" == "true" ]]; then
    cmd+=(--clear-storage)
fi

get_target_height() {
    local heights="$1"
    echo "$heights" | awk -F, '{gsub(/ /, "", $NF); print $NF}'
}

get_current_block_height() {
    curl -sf --connect-timeout 2 --max-time 3 "$endpoint/testnet/block/height/latest" 2>/dev/null || true
}

get_current_address() {
    if [[ -n "${PROTOCOL:-}" ]]; then
        echo "$PROTOCOL"
        return
    fi
    if [[ -n "${PRIVATE_KEY:-}" ]]; then
        leo account import "$PRIVATE_KEY" 2>/dev/null | rg -o 'aleo1[a-z0-9]{58}' | tail -1 || true
    fi
}

nudge_block_production() {
    local current_address="$1"
    if [[ -z "$current_address" ]]; then
        return
    fi
    # Best-effort tiny self-transfer to create transactions and encourage block production.
    leo execute transfer_public "$current_address" 0u64 --program credits.aleo --broadcast --yes --devnet >/dev/null 2>&1 || true
}

target_height=$(get_target_height "$effective_consensus_heights")
if ! [[ "$target_height" =~ ^[0-9]+$ ]]; then
    echo "Failed to determine target block height from consensus heights: $effective_consensus_heights"
    exit 1
fi

current_address=""
if [[ "$force_mine" == "true" ]]; then
    current_address=$(get_current_address)
fi

"${cmd[@]}" &
devnet_pid=$!

cleanup() {
    if kill -0 "$devnet_pid" >/dev/null 2>&1; then
        kill "$devnet_pid" >/dev/null 2>&1 || true
    fi
}
trap cleanup INT TERM

echo "Waiting for devnet at $endpoint to reach block height $target_height..."
last_progress_height=""
last_progress_ts=0
last_mined_height=""
while true; do
    if ! kill -0 "$devnet_pid" >/dev/null 2>&1; then
        wait "$devnet_pid"
        exit $?
    fi

    current_height=$(get_current_block_height)

    now_ts=$(date +%s)
    if [[ "$current_height" =~ ^[0-9]+$ ]]; then
        if [[ -n "$last_mined_height" ]] && [[ "$current_height" != "$last_mined_height" ]]; then
            echo "New block mined: $current_height"
        fi
        last_mined_height="$current_height"

        if [[ "$current_height" != "$last_progress_height" ]] || (( now_ts - last_progress_ts >= 5 )); then
            echo "Waiting progress: block $current_height / $target_height"
            last_progress_height="$current_height"
            last_progress_ts=$now_ts
        fi
    elif (( now_ts - last_progress_ts >= 5 )); then
        echo "Waiting progress: endpoint not ready yet..."
        last_progress_ts=$now_ts
    fi

    if [[ "$current_height" =~ ^[0-9]+$ ]] && [[ "$current_height" -ge "$target_height" ]]; then
        echo "Devnet reached block height $current_height (target: $target_height)."
        break
    fi

    if [[ "$force_mine" == "true" ]]; then
        nudge_block_production "$current_address"
    fi

    sleep 1
done

wait "$devnet_pid"
