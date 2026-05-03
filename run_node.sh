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

# Fail early with a clear message if install was not requested and snarkos is missing.
if [[ "$install" != "true" ]] && [[ ! -x "$snarkos_path" ]]; then
    echo "snarkOS not found or not executable at $snarkos_path"
    echo "Run ./run_node.sh --install to build it."
    exit 1
fi

cmd=(
    leo devnet --yes
    --snarkos "$snarkos_path"
    --snarkos-features test_network
    --consensus-heights 0,1,2,3,4,5,6,7,8,9,10,11
)

if [[ "$install" == "true" ]]; then
    cmd+=(--install)
fi

if [[ "$clean" == "true" ]]; then
    cmd+=(--clear-storage)
fi

"${cmd[@]}"
