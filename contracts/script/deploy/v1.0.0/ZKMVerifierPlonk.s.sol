// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "../../utils/Base.s.sol";
import {ZKMVerifier} from "../../../src/v1.0.0/ZKMVerifierPlonk.sol";
import {ZKMVerifierGateway} from "../../../src/ZKMVerifierGateway.sol";
import {IZKMVerifierWithHash} from "../../../src/IZKMVerifier.sol";

contract ZKMVerifierScript is BaseScript {
    string internal constant KEY = "V1_0_0_ZKM_VERIFIER_PLONK";

    function run() external multichain(KEY) broadcaster {
        // Read config
        bytes32 CREATE2_SALT = readBytes32("CREATE2_SALT");
        address ZKM_VERIFIER_GATEWAY = readAddress("ZKM_VERIFIER_GATEWAY_PLONK");

        // Deploy contract
        address verifier = address(new ZKMVerifier{salt: CREATE2_SALT}());

        // Add the verifier to the gateway
        ZKMVerifierGateway gateway = ZKMVerifierGateway(ZKM_VERIFIER_GATEWAY);
        gateway.addRoute(verifier);

        // Write address
        writeAddress(KEY, verifier);
    }

    function freeze() external multichain(KEY) broadcaster {
        // Read config
        address ZKM_VERIFIER_GATEWAY = readAddress("ZKM_VERIFIER_GATEWAY_PLONK");
        address ZKM_VERIFIER = readAddress(KEY);

        // Freeze the verifier on the gateway
        ZKMVerifierGateway gateway = ZKMVerifierGateway(ZKM_VERIFIER_GATEWAY);
        bytes4 selector = bytes4(IZKMVerifierWithHash(ZKM_VERIFIER).VERIFIER_HASH());
        gateway.freezeRoute(selector);
    }
}
