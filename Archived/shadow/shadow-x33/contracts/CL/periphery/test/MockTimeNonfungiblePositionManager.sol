// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.x;
pragma abicoder v2;

import '../NonfungiblePositionManager.sol';

contract MockTimeNonfungiblePositionManager is NonfungiblePositionManager {
    uint256 time;

    constructor(
        address _factory,
        address _WETH9,
        address _tokenDescriptor,
        address _voter
    ) NonfungiblePositionManager(_factory, _WETH9, _tokenDescriptor, _voter) {}

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }

    function setTime(uint256 _time) external {
        time = _time;
    }
}
