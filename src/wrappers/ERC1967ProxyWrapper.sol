// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC1967Proxy} from "@openzeppelin-contracts-5.1.0/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC1967ProxyWrapper is ERC1967Proxy {
    constructor(address implementation, bytes memory _data) payable ERC1967Proxy(implementation, _data) {}
}
