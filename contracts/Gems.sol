
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Gems is ERC20, ERC20Burnable, ERC20Permit {
    error NOT_ACCESS_HUB();
    address public immutable accessHub;

    modifier onlyAccessHub() {
        require(msg.sender == accessHub, NOT_ACCESS_HUB());
        _;
    }
    constructor(address _accessHub) ERC20("Shadow Wrapped Gems", "GEMS") ERC20Permit("Shadow Wrapped Gems") {
        accessHub = _accessHub;
    }

    function mint(address to, uint256 amount) onlyAccessHub() public {
        _mint(to, amount);
    }
}
