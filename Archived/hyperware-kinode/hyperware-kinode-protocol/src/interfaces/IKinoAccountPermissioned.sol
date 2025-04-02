// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

interface IKinoAccountPermissioned {
    function auth(address who, uint256 allowance) external;

    function deauth(address who) external;

    function allowance(address who) external view returns (uint256);
}
