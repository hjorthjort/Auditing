pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INonfungiblePositionManager} from "contracts/CL/periphery/interfaces/INonfungiblePositionManager.sol";
import {GaugeV3} from "contracts/CL/gauge/GaugeV3.sol";
import {IShadowV3Factory} from "contracts/CL/core/interfaces/IShadowV3Factory.sol";
import {IShadowV3Pool} from "contracts/CL/core/interfaces/IShadowV3Pool.sol";
import {IVoter} from "contracts/interfaces/IVoter.sol";

contract InsallahTest is Test {
    address public VOTER = 0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f;
    address public NFP_MANAGER_NEW = 0x12E66C8F215DdD5d48d150c8f46aD0c6fB0F4406;
    address public ANON_GAUGE = 0x1CF16D22409bFf9A133CF4c346ae4F9AFD4E0380;
    address public XSHADOW = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;
    address public V3_FACTORY = 0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7;
    uint256 public tokenId = 15359;

    function test_resetEarned() public {
        // positions
        (address token0, address token1, int24 tickSpacing,,, uint128 liquidity,,,,) =
            INonfungiblePositionManager(NFP_MANAGER_NEW).positions(tokenId);

        address poolAddress = IShadowV3Factory(V3_FACTORY).getPool(token0, token1, tickSpacing);
        /// config
        console.log("lastPeriod():", IShadowV3Pool(poolAddress).lastPeriod());
        console.log("liquidity:", liquidity);
        console.log("earned() before:", GaugeV3(ANON_GAUGE).earned(XSHADOW, tokenId));
        address bob = makeAddr("bob");
        uint256 amounts = 10000000000 ether;
        deal(token0, bob, amounts * 1000);
        deal(token1, bob, amounts * 1000);

        console.log("---- DONATING TO POSITION ----");
        /// donate to his position after epoch flip
        vm.startPrank(bob);
        IERC20(token0).approve(NFP_MANAGER_NEW, type(uint256).max);
        IERC20(token1).approve(NFP_MANAGER_NEW, type(uint256).max);
        // INonfungiblePositionManager(NFP_MANAGER_NEW).increaseLiquidity(
        //     INonfungiblePositionManager.IncreaseLiquidityParams({
        //         tokenId: tokenId,
        //         amount0Desired: amounts,
        //         amount1Desired: amounts,
        //         amount0Min: 0,
        //         amount1Min: 0,
        //         deadline: block.timestamp
        //     })
        // );
        console.log("amountDonated:", amounts);
        (,,,,, uint128 liquidityAfter,,,,) = INonfungiblePositionManager(NFP_MANAGER_NEW).positions(tokenId);
        console.log("liquidityAfter:", liquidityAfter);

        console.log("---- FLIPPING EPOCH ----");
        console.log("---- Minting random NFP before a swap ----");
        skip(6 days);
        /// perform a random mint to trigger epoch flip

        INonfungiblePositionManager(NFP_MANAGER_NEW).mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                tickSpacing: tickSpacing,
                tickLower: -60000,
                tickUpper: 60000,
                amount0Desired: amounts,
                amount1Desired: amounts,
                amount0Min: 0,
                amount1Min: 0,
                recipient: bob,
                deadline: block.timestamp
            })
        );
        /// perform a random mint to trigger epoch flip
        console.log("voter.getPeriod() after:", IVoter(VOTER).getPeriod());
        console.log("earned() after:", GaugeV3(ANON_GAUGE).earned(XSHADOW, tokenId));

        vm.stopPrank();
    }
}
