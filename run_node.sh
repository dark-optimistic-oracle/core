#!/bin/zsh
set -e
#set -x

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

if [[ -n "${CONSENSUS_HEIGHTS:-}" ]]; then
    cmd+=(--consensus-heights "$CONSENSUS_HEIGHTS")
fi

if [[ "$install" == "true" ]]; then
    cmd+=(--install)
fi

if [[ "$clean" == "true" ]]; then
    cmd+=(--clear-storage)
fi

"${cmd[@]}"
