// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

interface IFeeRecipient {
    function initialize(address _feeDistributor) external;
    function notifyFees() external;
}
