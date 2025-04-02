// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

interface IKinoAccountPaid {
    error IncorrectPayment();
    error WithdrawFailed();
    error InvalidPrice();

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    function setPrice(uint256 newPrice) external;

    function currentPrice() external view returns (uint256);

    function withdraw() external;
}
