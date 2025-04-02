//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.27;

import {IERC721} from "@openzeppelin-contracts-5.1.0/token/ERC721/IERC721.sol";

import {TokenBoundMech} from "./TokenBoundMech.sol";

/**
 * @dev A Mech that is operated by the holder of an ERC721 non-fungible token
 */
contract ERC721TokenBoundMech is TokenBoundMech {
    function isOperator(address signer) public view override returns (bool) {
        (, address tokenContract, uint256 tokenId) = token();
        return IERC721(tokenContract).ownerOf(tokenId) == signer && signer != address(0);
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
