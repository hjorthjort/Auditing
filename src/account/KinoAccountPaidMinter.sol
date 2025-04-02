// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {KinoAccountMinterUpgradable} from "./KinoAccountMinterUpgradable.sol";

contract KinoAccountPaidMinter is KinoAccountMinterUpgradable {
    // Errors
    error IncorrectPayment();
    error WithdrawFailed();
    error InvalidPrice();

    uint256 public currentPrice;

    // Events
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    // Gaps
    uint256[49] __gaps;

    constructor(address _kimap) KinoAccountMinterUpgradable(_kimap) {}

    function initialize(uint256 initialPrice) public initializer {
        if (initialPrice == 0) revert InvalidPrice();
        currentPrice = initialPrice;
        __UUPSUpgradeable_init();
    }

    function setPrice(uint256 newPrice) external onlyOperator {
        if (newPrice == 0) revert InvalidPrice();
        uint256 oldPrice = currentPrice;
        currentPrice = newPrice;
        emit PriceUpdated(oldPrice, newPrice);
    }

    function withdraw() public onlyOperator {
        uint256 balance = address(this).balance;
        if (balance == 0) revert WithdrawFailed();

        address payable recipient = payable(msg.sender);
        (bool success,) = recipient.call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    function _mint(address to, bytes calldata name, bytes calldata initialization, address implementation)
        internal
        override
        returns (address tba)
    {
        if (msg.value != currentPrice) revert IncorrectPayment();
        return _KIMAP.mint(to, name, initialization, implementation);
    }
}
