// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {IERC6551Registry} from "erc6551-reference-0.3.1/src/interfaces/IERC6551Registry.sol";

import {IKimap} from "../interfaces/IKimap.sol";

contract KimapStorage {
    IERC6551Registry public constant ERC6551_REGISTRY = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);

    mapping(bytes32 => IKimap.Entry) public map;

    uint256[49] __gaps;
}
