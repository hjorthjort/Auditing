// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IAccessHub} from "contracts/interfaces/IAccessHub.sol";
import {IShadowV3Pool} from "contracts/CL/core/interfaces/IShadowV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IShadowV3Factory} from "contracts/CL/core/interfaces/IShadowV3Factory.sol";
contract EoaAsFeeCollector is Test {
    address public SHADOW_V3_FACTORY = 0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7;
    address public ACCESS_HUB = 0x5e7A9eea6988063A4dBb9CcDDB3E04C923E8E37f;
    address public RANDOM_EOA = makeAddr('randomEoa');
    address public GOGGLZ_LP = 0x1f4eFC47e5A5Ab6539d95A76e2dDE6d74462acEa;
    address public TREASURY = 0x5Be2e859D0c2453C9aA062860cA27711ff553432;
    address public TIMELOCK = 0x4577D5d9687Ee4413Fc0c391b85861F0a383Df50;
    
    function setUp() public {

    }

    function test_eoaAsFeeCollector() public {
        // only timelock can set fee collector
        vm.startPrank(TIMELOCK);
        IShadowV3Pool pool = IShadowV3Pool(GOGGLZ_LP);
        IAccessHub(ACCESS_HUB).setFeeCollectorInFactoryV3(RANDOM_EOA);
        //who is the feeCollector now?
        assertEq(IShadowV3Factory(SHADOW_V3_FACTORY).feeCollector(), RANDOM_EOA);  
        (uint256 pendingFee0, uint128 pendingFee1) = IShadowV3Pool(pool).protocolFees();
        //check pending fees to collect
        address token0pool = pool.token0();
        address token1pool = pool.token1();
        //collect fees
        vm.startPrank(RANDOM_EOA);
        IShadowV3Pool(pool).collectProtocol(RANDOM_EOA, uint128(pendingFee0), uint128(pendingFee1));
        //check if fees are collected (1 wei absolute error)
        assertApproxEqAbs(IERC20(token0pool).balanceOf(RANDOM_EOA), pendingFee0, 1);
        assertApproxEqAbs(IERC20(token1pool).balanceOf(RANDOM_EOA), pendingFee1, 1);
    }
}
