// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct TimelockInstance {
    address timelock;
    address admin;
    uint256 minDelay;
    address[] proposers;
    address[] executors;
}
