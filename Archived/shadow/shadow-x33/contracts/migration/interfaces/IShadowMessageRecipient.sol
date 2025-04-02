// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

interface IShadowMessageRecipient {
    /// @dev parameters of the x-chain msg
    struct LocalParameters {
        address user;
        uint256 amountMigrated;
    }

    function claim() external;

    function rescue(address) external;

    function setXShadow(address _xShadow) external;

    function claimable(address) external view returns (uint256);

    function userMigratedTotal(address) external view returns (uint256);
}
