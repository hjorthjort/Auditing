// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract create2Fugazzi is Test {
    function testComputeHardcodedCreate2Address() public {
        // Hardcoded values
        address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
        address GOGGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564;
        address POOL_DEPLOYER = 0xac8928aa7d2058dB2b0E8F0Fac4058fF45067A84;
        bytes32 initCodeHash = 0x45abd56e0874f11d842a55bc9bba133f39d9d0489dc6d4577701e8f47faf7151;

        // Encode the salt
        bytes32 salt = keccak256(
            abi.encodePacked(
                WS,
                GOGGLZ,
                int24(200)
            )
        );

        // Compute the expected address using Foundry's cheatcode
        address expectedAddress = vm.computeCreate2Address(salt, initCodeHash, POOL_DEPLOYER);

        // Log the results
        emit log_named_address("Correct pair", 0x59E97aD2bb8f304C51a6eCc450224f5A963b3FdB);
        emit log_named_address("Foundry pair", expectedAddress);

        // Assert the calculated address matches the expected correct address
        assertEq(expectedAddress, 0x59E97aD2bb8f304C51a6eCc450224f5A963b3FdB, "The calculated address is incorrect");
    }
}