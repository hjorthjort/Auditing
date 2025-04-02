// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(uint256 amount) ERC20("", "") {
        _mint(msg.sender, amount);
    }
}
