// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable-5.1.0/proxy/utils/UUPSUpgradeable.sol";

contract UpgradeTest is UUPSUpgradeable {
    function _authorizeUpgrade(address) internal override {}

    function initialize() public initializer {}

    function success() public pure returns (bool) {
        return true;
    }
}
