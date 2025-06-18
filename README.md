# zkMIPS Contracts

This repository contains the smart contracts for verifying [zkMIPS](https://github.com/zkMIPS/zkMIPS) EVM proofs.

## Installation

To install the latest release version:

```bash
forge install zkMIPS/zkm-contracts
```

Add `@zkm-contracts/=lib/zkm-contracts/contracts/src/` in `remappings.txt.`

### Usage

Once installed, you can import the `IZKMVerifier` interface and use it in your contract:

```solidity
pragma solidity ^0.8.20;

import {IZKMVerifier} from "@zkm-contracts/IZKMVerifier.sol";

contract MyContract {
    address public constant ZKM_VERIFIER = 0xc5D7431F2b2e794886e38C57B2E974A7b71863FD;

    bytes32 public constant PROGRAM_VKEY = ...;

    function myFunction(..., bytes calldata publicValues, bytes calldata proofBytes) external {
        IZKMVerifier(ZKM_VERIFIER).verifyProof(PROGRAM_VKEY, publicValues, proofBytes);
    }
}
```

You can obtain the correct `ZKM_VERIFIER` address for your chain by looking in the [deployments](./contracts/deployments) directory, it's recommended to use the `ZKM_VERIFIER_GATEWAY` address which will automatically route proofs to the correct verifier based on their version.

You can obtain the correct `PROGRAM_VKEY` for your program calling the `setup` function for your ELF:

```rs
    let client = ProverClient::new();
    let (_, vk) = client.setup(ELF);
    println!("PROGRAM_VKEY = {}", vk.bytes32());
```

### Test

```
cd contracts
forge test
```

### Deployments

To deploy the contracts, ensure your [.env](./contracts/.env.example) file is configured with all the chains you want to deploy to.

Then you can use the `forge script` command and specify the specific contract you want to deploy. For example, to deploy the zkMIPS Verifier Gateway for PLONK you can run:

```bash
FOUNDRY_PROFILE=deploy forge script ./script/deploy/ZKMVerifierGatewayPlonk.s.sol:ZKMVerifierGatewayScript --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast
```

or to deploy the zkMIPS Verifier Gateway for Groth16 you can run:

```bash
FOUNDRY_PROFILE=deploy forge script ./script/deploy/ZKMVerifierGatewayGroth16.s.sol:ZKMVerifierGatewayScript --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast
```

### Adding Verifiers

You can use the `forge script` command to specify which verifier you want to deploy and add to the gateway. For example to deploy the PLONK verifier and add it to the PLONK gateway you can run:

```bash
FOUNDRY_PROFILE=deploy forge script ./script/deploy/v1.0.0/ZKMVerifierPlonk.s.sol:ZKMVerifierScript --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast
```

or to deploy the Groth16 verifier and add it to the Groth16 gateway you can run:

```bash
FOUNDRY_PROFILE=deploy forge script ./script/deploy/v1.0.0/ZKMVerifierGroth16.s.sol:ZKMVerifierScript --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast
```

Change `v1.0.0` to the desired version to add.

### Freezing Verifiers

> [!WARNING]  
> **BE CAREFUL** When a freezing a verifier. Once it is frozen, it cannot be unfrozen, and it can no longer be routed to.

To freeze a verifier on the gateway, run:

```bash
FOUNDRY_PROFILE=deploy forge script ./script/deploy/v1.0.0/ZKMVerifierPlonk.s.sol:ZKMVerifierScript --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast --sig "freeze()"
```

Change `v1.0.0` to the desired version to freeze.

## For Developers: Integrate ZKM Contracts

This repository contains the EVM contracts for verifying ZKM PLONK EVM proofs.

You can find more details on the contracts in the [`contracts`](./contracts/README.md) directory.

Note: you should ensure that all the contracts are on Solidity version `0.8.20`.

## For Contributors

To update the zkMIPS contracts, please refer to the [`update`](./UPDATE_CONTRACTS.md) file.

# Reference

[sp1-contracts](https://github.com/succinctlabs/sp1-contracts.git)
