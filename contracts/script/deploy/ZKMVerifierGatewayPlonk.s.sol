// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "../utils/Base.s.sol";
import {ZKMVerifierGateway} from "../../src/ZKMVerifierGateway.sol";

contract ZKMVerifierGatewayScript is BaseScript {
    string internal constant KEY = "ZKM_VERIFIER_GATEWAY_PLONK";

    function run() external multichain(KEY) broadcaster {
        // Read config
        bytes32 CREATE2_SALT = readBytes32("CREATE2_SALT");
        address OWNER = readAddress("OWNER");

        // Deploy contract
        address gateway = address(new ZKMVerifierGateway{salt: CREATE2_SALT}(OWNER));

        // Write address
        writeAddress(KEY, gateway);
    }
}
