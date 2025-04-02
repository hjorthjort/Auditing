// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import "forge-std/Script.sol";
import {SwapRouter} from "../../../../../contracts/CL/periphery/SwapRouter.sol";
import {SwapRouterInstance} from "../instances/SwapRouterInstance.sol";

library SwapRouterLibrary {
    /**
     * @notice Deploys a new SwapRouter contract
     * @param deployer The address of the deployer contract
     * @param weth9 The address of the WETH9 contract
     * @return instance The deployment instance containing all relevant addresses
     */
    function deploy(address deployer, address weth9) internal returns (SwapRouterInstance memory instance) {
        // Deploy the swap router contract
        SwapRouter swapRouter = new SwapRouter(deployer, weth9);

        // Create and return the instance
        instance = SwapRouterInstance({swapRouter: address(swapRouter), deployer: deployer, weth9: weth9});
    }
}
