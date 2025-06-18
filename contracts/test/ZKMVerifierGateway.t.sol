// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ZKMVerifierGateway} from "../src/ZKMVerifierGateway.sol";
import {IZKMVerifierWithHash} from "../src/IZKMVerifier.sol";

import {
    IZKMVerifierGatewayEvents,
    IZKMVerifierGatewayErrors,
    VerifierRoute
} from "../src/IZKMVerifierGateway.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ZKMVerifierV1 is IZKMVerifierWithHash {
    function VERSION() external pure returns (string memory) {
        return "1";
    }

    function VERIFIER_HASH() public pure returns (bytes32) {
        return 0x19ff1d210e06a53ee50e5bad25fa509a6b00ed395695f7d9b82b68155d9e1065;
    }

    function verifyProof(bytes32, bytes calldata, bytes calldata proofBytes) external pure {
        assert(bytes4(proofBytes[:4]) == bytes4(VERIFIER_HASH()));
    }
}

contract ZKMVerifierV2 is IZKMVerifierWithHash {
    function VERSION() external pure returns (string memory) {
        return "2";
    }

    function VERIFIER_HASH() public pure returns (bytes32) {
        return 0xfd4b4d23a917e7d7d75deec81f86b55b1c86689a5e3a3c8ae054741af2a7fea8;
    }

    function verifyProof(bytes32, bytes calldata, bytes calldata proofBytes) external pure {
        assert(bytes4(proofBytes[:4]) == bytes4(VERIFIER_HASH()));
    }
}

contract ZKMVerifierGatewayTest is Test, IZKMVerifierGatewayEvents, IZKMVerifierGatewayErrors {
    address internal constant REMOVED_VERIFIER = address(1);
    bytes32 internal constant PROGRAM_VKEY = bytes32(uint256(1));
    bytes internal constant PUBLIC_VALUES = hex"";
    bytes internal constant PROOF_1 = hex"19ff1d210001";
    bytes internal constant PROOF_2 = hex"fd4b4d230002";

    address internal verifier1;
    address internal verifier2;
    address internal owner;
    address internal gateway;

    function setUp() public virtual {
        verifier1 = address(new ZKMVerifierV1());
        verifier2 = address(new ZKMVerifierV2());
        owner = makeAddr("owner");
        gateway = address(new ZKMVerifierGateway(owner));
    }

    /// @notice Should confirm that the test environment is set up correctly.
    function test_SetUp() public view {
        assertEq(ZKMVerifierGateway(gateway).owner(), owner);

        address verifier;
        bool frozen;
        (verifier, frozen) =
            ZKMVerifierGateway(gateway).routes(bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH()));
        assertEq(verifier, address(0));
        assertEq(frozen, false);

        (verifier, frozen) =
            ZKMVerifierGateway(gateway).routes(bytes4(ZKMVerifierV2(verifier2).VERIFIER_HASH()));
        assertEq(verifier, address(0));
        assertEq(frozen, false);
    }

    /// @notice Should succeed when the owner adds a verifier route.
    function test_AddRoute() public {
        // Add verifier route 1
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.expectEmit(true, true, true, true);
        emit RouteAdded(verifier1Selector, verifier1);
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier1);

        (address verifier, bool frozen) = ZKMVerifierGateway(gateway).routes(verifier1Selector);
        assertEq(verifier, verifier1);
        assertEq(frozen, false);
    }

    /// @notice Should revert when an account other than the owner tries to add a verifier route.
    function test_RevertAddRoute_WhenNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")
            )
        );
        vm.prank(makeAddr("notOwner"));
        ZKMVerifierGateway(gateway).addRoute(verifier1);
    }

    /// @notice Should revert when a verifier does not implement the IZKMVerifierWithHash interface.
    function test_RevertAddRoute_WhenNotZKMVerifier() public {
        vm.expectRevert();
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(makeAddr("notZKMVerifier"));
    }

    /// @notice Should revert when a verifier already exists that was added with the same selector.
    function test_RevertAddRoute_WhenAlreadyExists() public {
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.expectEmit(true, true, true, true);
        emit RouteAdded(verifier1Selector, verifier1);
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier1);

        vm.expectRevert(abi.encodeWithSelector(RouteAlreadyExists.selector, verifier1));
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier1);
    }

    /// @notice Should succeed when the owner freezes an existing verifier route.
    function test_FreezeRoute() public {
        // Add verifier route 1
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.expectEmit(true, true, true, true);
        emit RouteAdded(verifier1Selector, verifier1);
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier1);

        (address verifier, bool frozen) = ZKMVerifierGateway(gateway).routes(verifier1Selector);
        assertEq(verifier, verifier1);
        assertEq(frozen, false);

        vm.expectEmit(true, true, true, true);
        emit RouteFrozen(verifier1Selector, verifier1);
        vm.prank(owner);
        ZKMVerifierGateway(gateway).freezeRoute(verifier1Selector);

        (verifier, frozen) = ZKMVerifierGateway(gateway).routes(verifier1Selector);
        assertEq(verifier, verifier1);
        assertEq(frozen, true);
    }

    /// @notice Should revert when an account other than the owner tries to freeze a verifier route.
    function test_RevertFreezeRoute_WhenNotOwner() public {
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")
            )
        );
        vm.prank(makeAddr("notOwner"));
        ZKMVerifierGateway(gateway).freezeRoute(verifier1Selector);
    }

    /// @notice Should revert when a verifier route does not exist.
    function test_RevertFreezeRoute_WhenNoRoute() public {
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.expectRevert(abi.encodeWithSelector(RouteNotFound.selector, verifier1Selector));
        vm.prank(owner);
        ZKMVerifierGateway(gateway).freezeRoute(verifier1Selector);
    }

    /// @notice Should revert when a verifier route is already frozen.
    function test_RevertFreezeRoute_WhenRouteIsFrozen() public {
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier1);
        vm.prank(owner);
        ZKMVerifierGateway(gateway).freezeRoute(verifier1Selector);

        vm.expectRevert(abi.encodeWithSelector(RouteIsFrozen.selector, verifier1Selector));
        vm.prank(owner);
        ZKMVerifierGateway(gateway).freezeRoute(verifier1Selector);
    }

    /// @notice Should succeed when a proof that has the verifier selector is sent to the
    /// the verifier gateway which has those verifiers added.
    function test_VerifyProof() public {
        // Add verifier 1
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier1);

        // Add verifier 2
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier2);

        // Send a proof using verifier 1
        ZKMVerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_1);

        // Send a proof using verifier 2
        ZKMVerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_2);
    }

    /// @notice Should revert when a proof is sent to the verifier gateway which has no verifier
    /// route for the proof's verifier selector.
    function test_RevertVerifyProof_WhenNoRoute() public {
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.expectRevert(abi.encodeWithSelector(RouteNotFound.selector, verifier1Selector));
        ZKMVerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_1);
    }

    /// @notice Should revert when a proof is sent to the verifier gateway which has a verifier
    /// route that is frozen for the proof's verifier selector.
    function test_RevertVerifyProof_WhenRouteIsFrozen() public {
        bytes4 verifier1Selector = bytes4(ZKMVerifierV1(verifier1).VERIFIER_HASH());
        vm.prank(owner);
        ZKMVerifierGateway(gateway).addRoute(verifier1);
        vm.prank(owner);
        ZKMVerifierGateway(gateway).freezeRoute(verifier1Selector);

        vm.expectRevert(abi.encodeWithSelector(RouteIsFrozen.selector, verifier1Selector));
        ZKMVerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_1);
    }
}
