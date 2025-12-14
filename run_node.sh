#!/bin/zsh
set -e
#set -x

# Parse command line argument
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    cat << 'EOF'
Usage: ./run_node.sh [OPTION]

Run a local Aleo development network node.

Options:
  --clean         Remove the snarkos-data folder and start with fresh storage
  --keep-state    Start with persistent storage (keeps blockchain state between restarts)
  (no option)     Start with transient storage (default, clears storage on each run)
  --help, -h      Display this help message

Examples:
  ./run_node.sh              # Start node with fresh storage (default)
  ./run_node.sh --clean      # Clean storage and start fresh
  ./run_node.sh --keep-state # Start with persistent storage
EOF
    exit 0
fi

if [[ "$1" == "--clean" ]]; then
    # Remove the snarkos-data folder
    # amareleo-chain clean
    # rm -rf ./snarkos-data
    # echo "Cleaned snarkos-data folder"
    leo devnet --yes --snarkos ~/.cargo/bin/snarkos --snarkos-features test_network --clear-storage
elif [[ "$1" == "--keep-state" ]]; then
    # Start with persistent storage
    # amareleo-chain start --keep-state
    # snarkos start --nodisplay --dev 0 --validator --storage-path ./snarkos-data
    leo devnet --yes --snarkos ~/.cargo/bin/snarkos --snarkos-features test_network
else
    # Start a local development validator (transient storage)
    # amareleo-chain start
    # snarkos start --nodisplay --dev 0 --validator
    leo devnet --yes --snarkos ~/.cargo/bin/snarkos --snarkos-features test_network --clear-storage
fi
