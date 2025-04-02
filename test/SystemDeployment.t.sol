// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {ERC6551AccountLib} from "erc6551-reference-0.3.1/src/lib/ERC6551AccountLib.sol";
import {ERC1967Proxy} from "@openzeppelin-contracts-5.1.0/proxy/ERC1967/ERC1967Proxy.sol";

import {TestUtils} from "./Utils.sol";
import {NameEncoder} from "../src/utils/NameEncoder.sol";
import {IMech} from "../src/interfaces/IMech.sol";
import {Kimap} from "../src/kimap/Kimap.sol";

contract SystemDeployment is TestUtils {
    address constant CREATE2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    address payable public zeroTba;

    /// @notice Deploy the Kimap contract
    /// @param _zerothOwner The address of the owner of the zeroth node
    /// @return kimap The deployed Kimap (proxy) contract
    function deployKimap(address _zerothOwner) public returns (Kimap kimap) {
        setUpMultiCall();
        setUp6551();

        bytes32 salt = keccak256("kimap");

        address kimapImpl = address(
            uint160(
                uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2, salt, keccak256(type(Kimap).creationCode))))
            )
        );

        bytes memory proxyData = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(kimapImpl, abi.encodeWithSelector(Kimap.initialize.selector, _zerothOwner))
        );

        (bool success,) = CREATE2.call(abi.encodePacked(salt, type(Kimap).creationCode));
        require(success, "Failed to deploy kimap");
        (success,) = CREATE2.call(abi.encodePacked(salt, proxyData));
        require(success, "Failed to deploy kimap proxy");

        // ERC1967Proxy for Kimap
        kimap = Kimap(
            payable(
                address(
                    uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2, salt, keccak256(proxyData)))))
                )
            )
        );

        zeroTba = payable(kimap.tbaOf(bytes32(0)));
    }

    function callMint(
        Kimap kimap,
        address to,
        address _tba,
        bytes memory name,
        bytes memory initialization,
        address implementation
    ) public returns (address tba, bytes32 namehash) {
        bytes memory data = IMech(_tba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, to, name, initialization, implementation), 0
        );

        tba = abi.decode(data, (address));

        (,, uint256 node) = ERC6551AccountLib.token(tba);
        namehash = bytes32(node);
    }

    function checkMintCall(address tba, string memory fullname) internal view {
        (,, uint256 node) = ERC6551AccountLib.token(tba);
        bytes32 namehash = bytes32(node);
        (, bytes32 decoded) = NameEncoder.dnsEncodeName(fullname);
        assertEq(namehash, decoded);
    }
}
