// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.x;

import {Test, console2} from "forge-std/Test.sol";
import {x33} from "contracts/xShadow/x33.sol";
contract TestX33Test is Test {

    x33 public x33Contract;
    address public operator;

    function setUp() public {
        operator = makeAddr("operator");

        // start at January 1, 2024 00:00:00 UTC
        vm.warp(1704067200);

        // set up with fake addresses except operator
        x33Contract = new x33(
            operator,
            address(0x123),
            address(0x456),
            address(0x789),
            address(0xabc)
        );
    }

    function test_UnlockBehaviourUnlocked() public {
        vm.startPrank(operator);
        uint256 currentPeriod;
        uint256 periodBeforeFlip;
        uint256 startingPeriod = x33Contract.getPeriod();
        uint256 timeLeftInPeriod = ((x33Contract.getPeriod() + 1) * 1 weeks) - block.timestamp;
        
        // test 5 epochs in the unlocked timeframe
        for (uint256 i = 0; i < 5; i++) {
            periodBeforeFlip = x33Contract.getPeriod();
            // go to 1h after flip + unlock from bot
            skip(timeLeftInPeriod + 1 hours);
            x33Contract.unlock();
            currentPeriod = x33Contract.getPeriod();
            // advance back to where we already were on last period
            skip(1 weeks - timeLeftInPeriod);
            
            // verify that period is +1, and that it's still unlocked
            assertEq(periodBeforeFlip, currentPeriod-1);
            assertEq(x33Contract.isUnlocked(), true);
        }
    }

    function test_UnlockBehaviourLocked() public {
        vm.startPrank(operator);
        x33Contract.unlock();

        // test 5 epochs on the locked period
        for (uint256 i = 0; i < 5; i++) {
            uint256 periodBeforeFlip = x33Contract.getPeriod();
            uint256 timeLeftInPeriod = ((x33Contract.getPeriod() + 1) * 1 weeks) - block.timestamp;
            
            console2.log("block.timestamp:", block.timestamp);
            
            // travel to the locked period
            uint256 newTimestamp = block.timestamp + timeLeftInPeriod - 30 minutes;
            vm.warp(newTimestamp);
            console2.log("t-30min", block.timestamp);
            
            bool isUnlockedBeforeEpochflip = x33Contract.isUnlocked();

            // flip epoch
            vm.warp(newTimestamp + 5 hours);
            console2.log("t+5hour:", block.timestamp);
            
            uint256 periodAfterFlip = x33Contract.getPeriod();
            bool isUnlockedAfterEpochflipBeforeOperatorUnlock = x33Contract.isUnlocked();

            // verify that period is +1, and that it remained locked before and after flip
            // before operator unlocks
            assertEq(periodBeforeFlip, periodAfterFlip-1);
            assertEq(isUnlockedBeforeEpochflip, false);
            assertEq(isUnlockedAfterEpochflipBeforeOperatorUnlock, false);

            // bot unlocks
            x33Contract.unlock();
            assertEq(x33Contract.isUnlocked(), true);
        }
    }
}

