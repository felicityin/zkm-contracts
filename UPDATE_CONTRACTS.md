# Add a new ZKM Version to `zkm-contracts`

This section outlines the steps required to update the zkMIPS contracts repository with a new zkMIPS version. Follow these instructions to ensure the ZKM contracts are correctly updated and aligned with the latest version.

## Add ZKM Verifier Contracts

Let's add the verifier contracts for a new `zkm-sdk` tag.

1. Change the version tag in `Cargo.toml` to the target `zkMIPS` version.

```toml
[dependencies]
zkm-sdk = { git = "https://github.com/zkMIPS/zkMIPS", tag = "<ZKM_TAG>" }
```

2. Update `contracts/src` with the new verifier contracts.

```bash
cargo update

cargo run --bin artifacts --release
```

This will download the circuit artifacts for the zkMIPS version, and write the verifier contracts to `/contracts/src/{ZKM_CIRCUIT_VERSION}`.

## Create a new release

For users to use the contracts associated with a specific `zkm-sdk` tag, we need to create a new release.

1. Open a PR to add the changes to `main`.
2. After merging to `main`, create a release tag with the same version as the `zkm` tag used (e.g `1.0.0`). For release candidates (e.g. `v1.0.0`), the release tag should be a **pre-release** tag.
3. Now users will be able to install contracts for this version with `forge install zkMIPS/zkm-contracts@VERSION`. By default, `forge install` will install the latest release.

## Appendix

The zkMIPS Solidity contract artifacts are included in each release of `zkMIPS`. You can see how these are included in the `zkMIPS` repository [here](https://github.com/zkMIPS/zkMIPS/blob/main/crates/recursion/gnark-ffi/src/plonk_bn254.rs#L58-L88).
