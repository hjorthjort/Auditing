// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {SystemDeployment} from "./SystemDeployment.t.sol";
import {Kimap} from "../src/kimap/Kimap.sol";
import {KinoAccount9CharCommitMinter} from "../src/account/KinoAccount9CharCommitMinter.sol";
import {IKinoAccountMinter} from "../src/interfaces/IKinoAccountMinter.sol";
import {IKinoAccountCommittable} from "../src/interfaces/IKinoAccountCommittable.sol";
import {KinoAccount} from "../src/account/KinoAccount.sol";

contract KinoAccount9CharCommitMinterTest is SystemDeployment {
    Kimap internal kimap;
    address internal minterImpl;
    address internal basicKinoAccountImpl;
    address internal owner = address(1);
    address internal safe = address(255);
    IKinoAccountMinter internal mintedTba;

    function setUp() public {
        kimap = deployKimap(address(this));

        // Deploy default KinoAccount implementation
        basicKinoAccountImpl = address(new KinoAccount());

        // Deploy KinoAccount9CharCommitMinter implementation
        minterImpl = address(new KinoAccount9CharCommitMinter(address(kimap), 15 seconds, 5 minutes));
        address mintedTbaAddress;
        (mintedTbaAddress,) = callMint(
            kimap,
            address(this),
            zeroTba,
            "test",
            abi.encodeWithSelector(IKinoAccountMinter.initialize.selector),
            minterImpl
        );
        mintedTba = IKinoAccountMinter(mintedTbaAddress);

        // update block so that commit expiry method works properly
        vm.warp(block.timestamp + 10 minutes);
    }

    function testMintWithShortName() public {
        bytes memory name = "6chars"; // 6 characters should fail
        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));

        IKinoAccountCommittable(address(mintedTba)).commit(commit);

        vm.expectRevert("Label too short");
        IKinoAccountMinter(mintedTba).mint(address(this), name, hex"", basicKinoAccountImpl);
    }

    function testUnknownUser() public {
        bytes memory name = "this-is-a-very-long-name-that-should-pass";

        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));
        IKinoAccountCommittable(address(mintedTba)).commit(commit);

        vm.warp(block.timestamp + 1 minutes);
        IKinoAccountMinter(mintedTba).mint(address(this), name, hex"", basicKinoAccountImpl);
    }

    function testMintWithLongName() public {
        bytes memory name = "123123123";
        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));

        IKinoAccountCommittable(address(mintedTba)).commit(commit);
        vm.prank(address(22));
        vm.expectRevert(IKinoAccountCommittable.CommitNotFound.selector);
        IKinoAccountMinter(mintedTba).mint(address(this), name, hex"", basicKinoAccountImpl);
    }
}
