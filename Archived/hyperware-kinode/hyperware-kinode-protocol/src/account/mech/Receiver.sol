// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.27;

import {ERC721TokenReceiver} from "safe-global-safe-smart-account-1.4.1-3/contracts/interfaces/ERC721TokenReceiver.sol";
import {ERC1155TokenReceiver} from
    "safe-global-safe-smart-account-1.4.1-3/contracts/interfaces/ERC1155TokenReceiver.sol";
import {ERC777TokensRecipient} from
    "safe-global-safe-smart-account-1.4.1-3/contracts/interfaces/ERC777TokensRecipient.sol";

/**
 * @dev This contract implements the functions necessary to receive ether as well as ERC721, ERC1155 and ERC777 tokens.
 */
contract Receiver is ERC1155TokenReceiver, ERC777TokensRecipient, ERC721TokenReceiver {
    receive() external payable virtual {}

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        view
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        view
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        external
        view
        virtual
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata)
        external
        pure
        override
    {
        // for ERC-777 compatibility
    }
}
