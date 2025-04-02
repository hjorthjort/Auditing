// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "contracts/CL/universalRouter/UniversalRouter.sol";
import "contracts/CL/universalRouter/base/RouterImmutables.sol";
import {IPairFactory} from "contracts/interfaces/IPairFactory.sol";

contract DeployUniversalRouter is Script {
    UniversalRouter public router;
    address constant PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);  
    address constant WETH9 = address(0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38);   
    address constant V2_FACTORY = address(0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8);  
    address constant V3_FACTORY = address(0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7);  
    bytes32 constant V3_INIT_CODE_HASH = bytes32(0xc701ee63862761c31d620a4a083c61bdc1e81761e6b9c9267fd19afd22e0821d);  
    
    function run() external {  // Removed parameters since we're using constants
        vm.startBroadcast();

        router = new UniversalRouter(RouterParameters(
            PERMIT2,    // permit2
            WETH9,     // WETH9
            address(0), // looksRareV2
            address(0), // operator
            address(0), // sudoswap
            address(0), // nftx
            address(0), // x2y2
            address(0), // foundation
            address(0), // seaport
            address(0), // seaportV1_4
            address(0), // nft20
            address(0), // cryptopunks
            address(0), // looksRare
            address(0), // routerRewardsDistributor
            address(0), // looksRareRewardsDistributor
            address(0), // looksRareToken
            V2_FACTORY,  // v2 factory
            V3_FACTORY,  // v3 factory
            IPairFactory(V2_FACTORY).pairCodeHash(), // v2 init code hash
            V3_INIT_CODE_HASH  // v3 init code hash
        ));

        console.log("UniversalRouter deployed to:", address(router));

        vm.stopBroadcast();
    }
}
