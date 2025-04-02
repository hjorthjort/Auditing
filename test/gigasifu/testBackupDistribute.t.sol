// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessHub} from "contracts/interfaces/IAccessHub.sol";
import {IVoter} from "contracts/interfaces/IVoter.sol";
import {XShadow} from "contracts/xShadow/XShadow.sol";
import {IMinter} from "contracts/interfaces/IMinter.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IFeeRecipient} from "contracts/interfaces/IFeeRecipient.sol";
contract TestBackupDistribute is Test {
    address public MSIG = 0x5Be2e859D0c2453C9aA062860cA27711ff553432;
    address public ACCESS_HUB = 0x5e7A9eea6988063A4dBb9CcDDB3E04C923E8E37f;
    address public VOTER = 0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f;
    address public XSHADOW = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;
    address public SHADOW = 0x3333b97138D4b086720b5aE8A7844b1345a33333;
    address public MINTER = 0xc7022F359cD1bDa8aB8a19d1F19d769cbf7F3765;
    address public SHADOW_S_LP = 0xF19748a0E269c6965a84f8C98ca8C47A064D4dd0;

    function test_notifyLegacyBribeToTreasury() public {
        vm.startPrank(VOTER);
        uint256 balanceBeforeMSIG = IERC20(SHADOW_S_LP).balanceOf(MSIG);
        IFeeRecipient(0xB9b20d182d29F7769fa7805B8d7F648f2825386B).notifyFees();
        uint256 balanceAfterMSIG = IERC20(SHADOW_S_LP).balanceOf(MSIG);
        console.log("Balance before MSIG:", balanceBeforeMSIG);
        console.log("Balance after MSIG:", balanceAfterMSIG);
    }


    function test_backupDistributeAll() public {
        address dawg = 0xCAfc58De1E6A071790eFbB6B83b35397023E1544;
        
        // pre pause xshadow
        vm.prank(ACCESS_HUB);
        XShadow(XSHADOW).pause();

        // try to vote while paused
        console.log("----CASTING A VOTE WHILE PAUSED----");
        vm.prank(MSIG);
        address[] memory pools = new address[](1);
        pools[0] = SHADOW_S_LP;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 25;
        IVoter(VOTER).vote(
            MSIG,        
            pools,  
            weights
        );

        vm.startPrank(dawg);
        bool isPausedBefore = Pausable(XSHADOW).paused();
        uint256 pendingRebaseBefore = XShadow(XSHADOW).pendingRebase();
        uint256 ahBalanceBefore = IERC20(SHADOW).balanceOf(ACCESS_HUB);
        uint256 voterBalanceBefore = IERC20(SHADOW).balanceOf(VOTER);

        skip(4 days);
        IAccessHub(ACCESS_HUB).backupDistribute();

        uint256 ahBalanceAfter = IERC20(SHADOW).balanceOf(ACCESS_HUB);
        uint256 voterBalanceAfter = IERC20(SHADOW).balanceOf(VOTER);
        uint256 pendingRebaseAfter = XShadow(XSHADOW).pendingRebase();
        bool isPausedAfter = Pausable(XSHADOW).paused();
        console.log("----BEFORE BACKUP DISTRIBUTE----");
        console.log("AccessHub SHADOW:", ahBalanceBefore);
        console.log("Voter SHADOW:", voterBalanceBefore);
        console.log("isPaused:", isPausedBefore);
        console.log("pendingRebase:", pendingRebaseBefore);
        console.log("----AFTER BACKUP DISTRIBUTE----");
        console.log("AccessHub SHADOW:", ahBalanceAfter);
        console.log("isPaused:", isPausedAfter);
        console.log("Voter SHADOW:", voterBalanceAfter);
        console.log("pendingRebase:", pendingRebaseAfter);


        vm.stopPrank();
    }
}
