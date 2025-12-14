# Versions

## Before upgrading

```shell
% leo --version
leo 2.6.1
% snarkos --version
snarkos unknown_branch 8c7ea6cd0e5f1ebcba59f73275de666feb1ce9a6 features=[default,snarkos_node_metrics]
% amareleo-chain --version
amareleo-chain 2.2.0 unknown_branch 338802d42f585bdac37fc4bbdf106e8e278eefcb features=[amareleo_node_metrics,default]
% snarkvm update
🟢 A new version is available! Run `aleo update` to update to v4.0.0.
Checking target-arch... aarch64-apple-darwin
Checking current version... v1.5.0
Checking latest released version... v4.0.0
New release found! v1.5.0 --> v4.0.0
New release is *NOT* compatible

Failed to update Aleo to the latest version
ReleaseError: No asset found for target: `aarch64-apple-darwin`
```

## After upgrading

Leo:
```shell
% leo update

🟢 A new version is available! Run `leo update` to update to v3.4.0.
Checking target-arch... aarch64-apple-darwin
Checking current version... v2.6.1
Checking latest released version... v3.4.0
New release found! v2.6.1 --> v3.4.0
New release is *NOT* compatible

leo release status:
  * Current exe: "/Users/jordan/.cargo/bin/leo"
  * New exe release: "leo-v3.4.0-aarch64-apple-darwin.zip"
  * New exe download url: "https://api.github.com/repos/ProvableHQ/leo/releases/assets/323589008"

The new release will be downloaded/extracted and the existing binary will be replaced.
Downloading...
[00:00:00] [========================================] 25.41 MiB/25.41 MiB (0s) Done                                                                             Extracting archive... Done
Replacing binary file... Done
       Leo 
Leo has updated to version 3.4.0
```

SnarkOS:
```shell
% cargo install snarkos --features test_network
...
Replaced package `snarkos v3.5.0 (/Users/jordan/src/Aleo/snarkOS)` with `snarkos v4.4.0` (executable `snarkos`)
```

Amareleo (version 2.5.0 not compatible with snarkOS v4.4.0):
```shell
% git clone https://github.com/kaxxa123/amareleo-chain
cd amareleo-chain
...
amareleo-chain % cargo build --release
...
amareleo-chain % cp target/release/amareleo-chain ~/.cargo/bin/amareleo-chain
% amareleo-chain --version
amareleo-chain 2.5.0 refs/heads/main dbee6db7a95d0e48496322192c0d85a26f65614e features=[amareleo_node_metrics,default]
```