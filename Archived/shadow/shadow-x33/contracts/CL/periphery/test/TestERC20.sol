// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.x;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';

contract TestERC20 is ERC20Permit {
    constructor(uint256 amountToMint) ERC20('Test ERC20', 'TEST') ERC20Permit('Test ERC20') {
        _mint(msg.sender, amountToMint);
    }
}
