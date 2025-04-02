// scratchpad for quick random tests
pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {INonfungiblePositionManager} from 'contracts/CL/periphery/interfaces/INonfungiblePositionManager.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IShadowV3Pool} from 'contracts/CL/core/interfaces/IShadowV3Pool.sol';
import {ISwapRouter} from 'contracts/CL/periphery/interfaces/ISwapRouter.sol';

contract SafuScratchpad is Test {
    address NFP_MANAGER = 0xA57FA38b3fd45922394e9E1077748A2383F1542E;
    address NFP_MANAGER_NEW = 0x12E66C8F215DdD5d48d150c8f46aD0c6fB0F4406;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address GOGGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564;
    address SHADOW_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // function test_mint() public {
    //     address bob = makeAddr('bob');
    //     deal(WS, bob, 1_000 ether);
    //     deal(GOGGLZ, bob, 1_000 ether);
    //     vm.startPrank(bob);
    //     IERC20(WS).approve(address(NFP_MANAGER), type(uint256).max);
    //     IERC20(GOGGLZ).approve(address(NFP_MANAGER), type(uint256).max);

    //     (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = INonfungiblePositionManager(NFP_MANAGER).mint(INonfungiblePositionManager.MintParams({
    //         token0: WS,
    //         token1: GOGGLZ,
    //         tickSpacing: 200,
    //         tickLower: -100000,
    //         tickUpper: 100000,
    //         amount0Desired: 100 ether,
    //         amount1Desired: 100 ether,
    //         amount0Min: 0,
    //         amount1Min: 0,
    //         recipient: bob,
    //         deadline: block.timestamp
    //     }));

    //     console.log('tokenId', tokenId);
    //     console.log('liquidity', liquidity);
    //     console.log('amount0', amount0);
    //     console.log('amount1', amount1);

    //     vm.stopPrank();
    // }

    // function test_mintReversedTokenOrder() public {
    //     address bob = makeAddr('bob');
    //     deal(WS, bob, 1_000 ether);
    //     deal(GOGGLZ, bob, 1_000 ether);
    //     vm.startPrank(bob);
    //     IERC20(WS).approve(address(NFP_MANAGER), type(uint256).max);
    //     IERC20(GOGGLZ).approve(address(NFP_MANAGER), type(uint256).max);

    //     (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = INonfungiblePositionManager(NFP_MANAGER).mint(INonfungiblePositionManager.MintParams({
    //         token0: GOGGLZ,
    //         token1: WS,
    //         tickSpacing: 200,
    //         tickLower: -100000,
    //         tickUpper: 100000,
    //         amount0Desired: 100 ether,
    //         amount1Desired: 100 ether,
    //         amount0Min: 0,
    //         amount1Min: 0,
    //         recipient: bob,
    //         deadline: block.timestamp
    //     }));

    //     console.log('tokenId', tokenId);
    //     console.log('liquidity', liquidity);
    //     console.log('amount0', amount0);
    //     console.log('amount1', amount1);

    //     vm.stopPrank();
    // }

    // function test_mintAndInitializeNonPayable() public {
    //     address ocho = 0x00000008Fd2c6E6d7D6248Edb06B00566C13AF11;
    //     vm.startPrank(ocho);
    //     // Deal WS token instead of native ETH
    //     deal(WS, ocho, 1_000_000_000 ether);
    //     deal(GOGGLZ, ocho, 1_000_000_000 ether);
    //     // Need both approvals
    //     IERC20(WS).approve(address(NFP_MANAGER), type(uint256).max);
    //     IERC20(GOGGLZ).approve(address(NFP_MANAGER), type(uint256).max);
    //     // configure pool
    //     int24 tickSpacing = 10;
    //     uint160 sqrtPriceX96 = 137227202865029797602485611888; // tick = 10986
    //     IShadowV3Pool pool = IShadowV3Pool(INonfungiblePositionManager(NFP_MANAGER).createAndInitializePoolIfNecessary(WS, GOGGLZ, tickSpacing, sqrtPriceX96)); 
    //     (, int24 tick,,,,,) = pool.slot0();
    //     console.log('##POOL_INFO###');
    //     console.log("address", address(pool));
    //     console.log("sqrtPriceX96", sqrtPriceX96);
    //     console.log("tickSpacing", tickSpacing);
    //     console.log("tick", tick);
    //     // configure position
    //     int24 tickLower = 0;
    //     int24 tickUpper = 500;
    //     uint256 amount0Desired = 1000 ether;
    //     uint256 amount1Desired = 1000 ether;

    //     (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = INonfungiblePositionManager(NFP_MANAGER).mint(
    //         INonfungiblePositionManager.MintParams({
    //             token0: WS,
    //             token1: GOGGLZ,
    //             tickSpacing: tickSpacing,
    //             tickLower: tickLower,
    //             tickUpper: tickUpper,
    //             amount0Desired: amount0Desired,
    //             amount1Desired: amount1Desired,
    //             amount0Min: 0,
    //             amount1Min: 0,
    //             recipient: ocho,
    //             deadline: block.timestamp + 1000000
    //         })
    //     );


    //     console.log("###POSITION_INFO###");
    //     console.log("tokenId", tokenId);
    //     console.log("tickLower", tickLower);
    //     console.log("tickUpper", tickUpper);
    //     console.log("amount0Desired", amount0Desired);
    //     console.log("amount1Desired", amount1Desired);
    //     console.log("amount0", amount0);
    //     console.log("amount1", amount1);
    //     console.log("liquidity", liquidity);

    //     vm.stopPrank();
    // }

    // function test_mintAndInitializePayable() public {
    //     address ocho = 0x00000008Fd2c6E6d7D6248Edb06B00566C13AF11;
    //     vm.startPrank(ocho);
    //     // Deal native ETH
    //     vm.deal(ocho, 1_000_000_000 ether);
    //     deal(GOGGLZ, ocho, 1_000_000_000 ether);
    //     // Only GOGGLZ approval needed
    //     IERC20(GOGGLZ).approve(address(NFP_MANAGER), type(uint256).max);
    //     INonfungiblePositionManager(NFP_MANAGER).createAndInitializePoolIfNecessary(WS, GOGGLZ, 10, 137227202865029797602485611888); 

    //     (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = INonfungiblePositionManager(NFP_MANAGER).mint{value: 8879950781135227}(
    //         INonfungiblePositionManager.MintParams({
    //             token0: WS,
    //             token1: GOGGLZ,
    //             tickSpacing: 10,
    //             tickLower: 9650,
    //             tickUpper: 12165,
    //             amount0Desired: 8879950781135227,
    //             amount1Desired: 30226126907959948,
    //             amount0Min: 0,
    //             amount1Min: 0,
    //             recipient: ocho,
    //             deadline: block.timestamp + 1000000
    //         })
    //     );

    //     // Refund excessive native ETH
    //     INonfungiblePositionManager(NFP_MANAGER).refundETH();

    //     console.log('tokenId', tokenId);
    //     console.log('liquidity', liquidity);
    //     console.log('amount0', amount0);
    //     console.log('amount1', amount1);

    //     vm.stopPrank();
    // }

    // function test_collectBuggedNfp() public {
    //     address bob = 0x6CE6D64D7d26189Abe8E269dC0B2Af3003782511;
    //     IShadowV3Pool pool = IShadowV3Pool(0x6B1C77F98B5aFaB0E924A254d5263dD55D5e6FBB);
    //     address SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    //     (address token0, address token1) = (pool.token0(), pool.token1());
    //     deal(token0, bob, 1000 ether);
        
    //     vm.startPrank(bob);
    //     IERC20(token0).approve(SWAP_ROUTER, type(uint256).max);
    

    //     INonfungiblePositionManager(NFP_MANAGER).collect(INonfungiblePositionManager.CollectParams({
    //         tokenId: 281,
    //         recipient: bob,
    //         amount0Max: type(uint128).max,
    //         amount1Max: type(uint128).max
    //     }));
    //     vm.stopPrank();
    // }

    function test_collectQuesoNfp() public {
        address dawg = 0x84d0F74d21a89F86b67e9a38d8559d0b4e10F12d;
        vm.startPrank(dawg);
        INonfungiblePositionManager(NFP_MANAGER_NEW).collect(INonfungiblePositionManager.CollectParams({
            tokenId: 5584,
            recipient: dawg,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        }));
        vm.stopPrank();
    }

    function test_burnAndCollectQuesoNfp() public {

        address victim = 0xC9eebecb1d0AfF4fb2B9978516E075A33639892C;
        uint tokenId = 9210;
        
        vm.startPrank(victim);

        (
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,
        ) = INonfungiblePositionManager(NFP_MANAGER_NEW).positions(tokenId);

        INonfungiblePositionManager(NFP_MANAGER_NEW).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        INonfungiblePositionManager(NFP_MANAGER_NEW).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: victim,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        // address[] memory rewardTokens = new address[](1);
        // rewardTokens[0] = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;
        // INonfungiblePositionManager(NFP_MANAGER_NEW).getReward(tokenId, rewardTokens);

        vm.stopPrank();
    }
}
