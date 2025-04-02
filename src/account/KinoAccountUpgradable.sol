// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {ERC721TokenBoundMech} from "./mech/ERC721TokenBoundMech.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable-5.1.0/proxy/utils/UUPSUpgradeable.sol";

contract KinoAccountUpgradable is ERC721TokenBoundMech, UUPSUpgradeable {
    function initialize() external virtual initializer {
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOperator {}
}
