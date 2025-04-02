// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {IKimap} from "./IKimap.sol";

interface IKinoAccountMinter {
    error InvalidSignature(address actual, address expected);

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address signer;
    }

    function initialize() external;

    function kimap() external view returns (IKimap);

    function getMessage(
        address to,
        bytes calldata name,
        bytes calldata initialization,
        address implementation,
        address signer
    ) external view returns (bytes32);

    function mintBySignature(
        address to,
        bytes calldata name,
        bytes calldata initialization,
        address implementation,
        Signature calldata signature
    ) external returns (address tba);

    function mint(address to, bytes calldata name, bytes calldata initialization, address implementation)
        external
        payable
        returns (address tba);
}
