// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import "forge-std/Script.sol";
import {NonfungiblePositionManager} from "../../../../../contracts/CL/periphery/NonfungiblePositionManager.sol";
import {NonfungiblePositionManagerInstance} from "../instances/NonfungiblePositionManagerInstance.sol";

library NonfungiblePositionManagerLibrary {
    /**
     * @notice Deploys a new NonfungiblePositionManager contract
     * @param deployer The address of the deployer contract
     * @param weth9 The address of the WETH9 contract
     * @param tokenDescriptor The address of the NFT position descriptor contract
     * @param voter The address of the voter contract
     * @return instance The deployment instance containing all relevant addresses
     */
    function deploy(address deployer, address weth9, address tokenDescriptor, address voter)
        internal
        returns (NonfungiblePositionManagerInstance memory instance)
    {
        // Deploy the position manager contract
        NonfungiblePositionManager positionManager =
            new NonfungiblePositionManager(deployer, weth9, tokenDescriptor, voter);

        // Create and return the instance
        instance = NonfungiblePositionManagerInstance({
            positionManager: address(positionManager),
            deployer: deployer,
            weth9: weth9,
            tokenDescriptor: tokenDescriptor,
            voter: voter
        });
    }
}
