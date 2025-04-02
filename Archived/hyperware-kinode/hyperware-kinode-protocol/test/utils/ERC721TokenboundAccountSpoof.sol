//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.27;

import {TokenBoundMech} from "../../src/account/mech/TokenBoundMech.sol";

/**
 * @dev A Mech that is operated by the holder of an ERC721 non-fungible token
 */
contract ERC721TokenboundAccountSpoof is TokenBoundMech {
    function isOperator(address) public pure override returns (bool) {
        return true;
    }

    function onERC721Received(address, address, uint256 receivedTokenId, bytes calldata)
        external
        view
        override
        returns (bytes4)
    {
        (, address boundTokenContract, uint256 boundTokenId) = token();

        if (msg.sender == boundTokenContract && receivedTokenId == boundTokenId) {
            revert OwnershipCycle();
        }

        return this.onERC721Received.selector;
    }
}
