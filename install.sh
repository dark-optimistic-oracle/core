#!/bin/zsh
set -e
set -x

# Run ./run_node.sh to start the node before running this script

. ./.env

if [[ -z "$NETWORK" || -z "$ENDPOINT" || -z "$PRIVATE_KEY" ]]; then
	echo "Missing one or more required vars in .env: NETWORK, ENDPOINT, PRIVATE_KEY"
	exit 1
fi

# Keep this aligned with run_node.sh local devnet consensus heights.
CONSENSUS_HEIGHTS="${CONSENSUS_HEIGHTS:-0,1,2,3,4,5,6,7,8,9,10,11,12,13}"

# Leo may return exit code 0 even when a broadcasted transaction is not found.
# Require an explicit confirmation marker in command output when provided.
run_leo_checked() {
	local step="$1"
	local success_marker="$2"
	shift 2

	local output
	local exit_code
	set +e
	output="$($@ 2>&1)"
	exit_code=$?
	set -e

	echo "$output"

	if (( exit_code != 0 )); then
		echo "ERROR: ${step} failed with exit code ${exit_code}."
		exit "$exit_code"
	fi

	if [[ "$output" == *"Could not find the transaction."* ]]; then
		echo "ERROR: ${step} transaction was not confirmed on-chain."
		exit 1
	fi

	if [[ -n "$success_marker" && "$output" != *"$success_marker"* ]]; then
		echo "ERROR: ${step} did not return confirmation marker: ${success_marker}"
		exit 1
	fi
}

install_token_registry() {
	local output
	local exit_code

	pushd ../token-registry-workaround
	set +e
	output="$(./install.sh 2>&1)"
	exit_code=$?
	set -e
	echo "$output"

	if (( exit_code != 0 )); then
		if [[ "$output" == *"Program ID 'token_registry.aleo' is already deployed"* ]]; then
			echo "token_registry.aleo already deployed; continuing."
		else
			echo "ERROR: token-registry-workaround/install.sh failed."
			exit "$exit_code"
		fi
	fi

	popd
}

echo "Using endpoint: $ENDPOINT"
echo "Consensus heights: $CONSENSUS_HEIGHTS"

echo "[1/4] install token registry dependency"
install_token_registry

echo "[2/4] leo clean && leo build"
leo clean
leo build

echo "[3/4] deploy or upgrade dark_optimistic_oracle.aleo"
set +e
DEPLOY_OUTPUT="$(leo deploy --yes --path . --devnet --broadcast --endpoint "$ENDPOINT" --private-key "$PRIVATE_KEY" --consensus-heights "$CONSENSUS_HEIGHTS" --max-wait 20 --blocks-to-check 100 2>&1)"
DEPLOY_EXIT=$?
set -e
echo "$DEPLOY_OUTPUT"

if (( DEPLOY_EXIT != 0 )); then
	if [[ "$DEPLOY_OUTPUT" == *"Program ID 'dark_optimistic_oracle.aleo' is already deployed"* ]]; then
		echo "dark_optimistic_oracle.aleo already deployed; running upgrade."
		run_leo_checked "upgrade" "Upgrade confirmed!" leo upgrade --yes --path . --devnet --broadcast --endpoint "$ENDPOINT" --private-key "$PRIVATE_KEY" --consensus-heights "$CONSENSUS_HEIGHTS" --max-wait 20 --blocks-to-check 100
	else
		echo "ERROR: deploy failed and did not match an auto-recoverable condition."
		exit "$DEPLOY_EXIT"
	fi
else
	if [[ "$DEPLOY_OUTPUT" != *"Deployment confirmed!"* ]]; then
		echo "ERROR: deploy did not return confirmation marker: Deployment confirmed!"
		exit 1
	fi
fi

echo "Waiting 10s before initialize..."
/bin/sleep 10

echo "[4/4] leo execute initialize"
set +e
INITIALIZE_OUTPUT="$(leo execute initialize --yes --devnet --broadcast --endpoint "$ENDPOINT" --private-key "$PRIVATE_KEY" --consensus-heights "$CONSENSUS_HEIGHTS" --max-wait 20 --blocks-to-check 100 2>&1)"
INITIALIZE_EXIT=$?
set -e
echo "$INITIALIZE_OUTPUT"

if (( INITIALIZE_EXIT != 0 )); then
	echo "ERROR: initialize failed with exit code ${INITIALIZE_EXIT}."
	exit "$INITIALIZE_EXIT"
fi

if [[ "$INITIALIZE_OUTPUT" == *"Execution confirmed!"* ]]; then
	:
elif [[ "$INITIALIZE_OUTPUT" == *"Transaction rejected."* ]]; then
	echo "initialize was rejected on-chain (likely already initialized); continuing."
else
	echo "ERROR: initialize did not return confirmation marker: Execution confirmed!"
	exit 1
fi

echo "Install completed successfully."
