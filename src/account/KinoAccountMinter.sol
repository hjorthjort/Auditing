// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {KinoAccountMinterUpgradable} from "./KinoAccountMinterUpgradable.sol";

contract KinoAccountMinter is KinoAccountMinterUpgradable {
    // Gaps
    uint256[49] __gaps;

    constructor(address _kimap) KinoAccountMinterUpgradable(_kimap) {}
}
