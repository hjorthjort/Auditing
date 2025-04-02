// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.x;

import {Test, console2} from "forge-std/Test.sol";
import {IX33} from "contracts/interfaces/IX33.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IAccessHub} from "contracts/interfaces/IAccessHub.sol";
import {IVoter} from "contracts/interfaces/IVoter.sol";

contract TestX33Test is Test {

    IX33 public x33 = IX33(0x3333111A391cC08fa51353E9195526A70b333333);
    address public MSIG = 0x5Be2e859D0c2453C9aA062860cA27711ff553432;
    address public KILLED_GAUGE_POOL = 0xe2554e0aE624b94B6EaC84b211793E060375928D;
    address public ACCESS_HUB = 0x5e7A9eea6988063A4dBb9CcDDB3E04C923E8E37f;
    address public VOTER = 0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f;

    function _deposit(uint256 depositAmount) internal returns (uint256) {
        vm.startPrank(x33.operator());
        
        address xShadow = address(x33.xShadow());
        deal(xShadow, x33.operator(), depositAmount * 2);
        IERC20(xShadow).approve(address(x33), type(uint256).max);  
        uint256 shares = IERC4626(address(x33)).mint(depositAmount, x33.operator());
        
        return shares;
    }

    function test_depositAndReviveGauge() public {
        /// revive the gauge
        address[] memory gauges = new address[](1);
        gauges[0] = KILLED_GAUGE_POOL;
        vm.startPrank(MSIG);
        IAccessHub(ACCESS_HUB).reviveGauge(gauges);
        /// submit the treasury vote
        address[] memory placeHolderPools = new address[](1);
        placeHolderPools[0] = 0xF19748a0E269c6965a84f8C98ca8C47A064D4dd0; /// S/SHADOW LP
        uint256[] memory placeHolderWeights = new uint256[](1);
        placeHolderWeights[0] = 100; 
        IVoter(VOTER).vote(MSIG, placeHolderPools, placeHolderWeights);
        vm.stopPrank();
        /// submit the x33 vote
        vm.prank(x33.operator());
        x33.submitVotes(placeHolderPools, placeHolderWeights);
        /// final mint (pray it works)
        _deposit(1e18);
    }
}
