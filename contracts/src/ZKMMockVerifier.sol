// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IZKMVerifier} from "./IZKMVerifier.sol";

/// @title ZKM Mock Verifier
/// @author ZKM Labs
/// @notice This contracts implements a Mock solidity verifier for ZKM.
contract ZKMMockVerifier is IZKMVerifier {
    /// @notice Verifies a mock proof with given public values and vkey.
    /// @param proofBytes The proof of the program execution the ZKM zkVM encoded as bytes.
    function verifyProof(bytes32, bytes calldata, bytes calldata proofBytes) external pure {
        assert(proofBytes.length == 0);
    }
}
