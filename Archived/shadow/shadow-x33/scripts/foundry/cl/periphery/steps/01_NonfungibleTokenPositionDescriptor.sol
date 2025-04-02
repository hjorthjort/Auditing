// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import "forge-std/Script.sol";
import {NonfungibleTokenPositionDescriptor} from
    "../../../../../contracts/CL/periphery/NonfungibleTokenPositionDescriptor.sol";
import {NonfungibleTokenPositionDescriptorInstance} from "../instances/NonfungibleTokenPositionDescriptorInstance.sol";

library NonfungibleTokenPositionDescriptorLibrary {
    /**
     * @notice Deploys a new NonfungibleTokenPositionDescriptor contract
     * @param weth9 The address of the WETH9 contract
     * @return instance The address of the deployed descriptor contract
     */
    function deploy(address weth9) internal returns (NonfungibleTokenPositionDescriptorInstance memory instance) {
        // Deploy the descriptor contract
        NonfungibleTokenPositionDescriptor descriptor = new NonfungibleTokenPositionDescriptor(weth9);

        // Verify the WETH9 address was set correctly
        require(NonfungibleTokenPositionDescriptor(descriptor).WETH9() == weth9, "Invalid WETH9 initialization");

        instance = NonfungibleTokenPositionDescriptorInstance({descriptor: address(descriptor), weth9: weth9});
        return instance;
    }
}
