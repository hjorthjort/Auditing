// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {ERC1967Utils} from "@openzeppelin-contracts-5.1.0/proxy/ERC1967/ERC1967Utils.sol";
import {Proxy} from "@openzeppelin-contracts-5.1.0/proxy/Proxy.sol";

contract KinoAccountProxy is Proxy {
    error NotKimapCaller(address);
    error AlreadyInitialized();

    address internal immutable KIMAP;
    bool private _initialized;

    constructor(address _kimap) {
        KIMAP = _kimap;
        _initialized = false;
    }

    receive() external payable {}

    function initialize(address implementation, bytes memory _data) external payable {
        if (msg.sender != KIMAP) {
            if (_initialized) _fallback();
            else revert NotKimapCaller(msg.sender);
        }
        if (_initialized) {
            revert AlreadyInitialized();
        }

        if (_implementation() == address(0)) {
            _initialized = true;
            ERC1967Utils.upgradeToAndCall(implementation, _data);
        }
    }

    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
