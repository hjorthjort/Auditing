// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

interface IShadowMessageSender {
    /// @dev parameters of the x-chain msg
    struct LocalParameters {
        address user;
        uint256 amountMigrated;
    }
    /// @notice function to go to sonic
    function toSonic() external payable;

}
