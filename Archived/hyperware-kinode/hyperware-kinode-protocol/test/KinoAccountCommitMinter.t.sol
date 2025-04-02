// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {SystemDeployment} from "./SystemDeployment.t.sol";
import {Kimap} from "../src/kimap/Kimap.sol";
import {KinoAccountCommitMinter} from "../src/account/KinoAccountCommitMinter.sol";
import {IKinoAccountMinter} from "../src/interfaces/IKinoAccountMinter.sol";
import {IKinoAccountCommittable} from "../src/interfaces/IKinoAccountCommittable.sol";
import {KinoAccount} from "../src/account/KinoAccount.sol";

contract KinoAccountCommitMinterTest is SystemDeployment {
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

        // Deploy KinoAccountCommitMinter implementation
        minterImpl = address(new KinoAccountCommitMinter(address(kimap), 15 seconds, 5 minutes));
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

    function testCommit() public {
        bytes memory name = "test-commit";
        bytes32 commitHash = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));

        IKinoAccountCommittable(address(mintedTba)).commit(commitHash);
        uint256 commitTimestamp = IKinoAccountCommittable(address(mintedTba)).getCommit(commitHash);
        assertEq(commitTimestamp, block.timestamp + KinoAccountCommitMinter(payable(address(mintedTba))).maxCommitAge());
    }

    function testCommitTwice() public {
        bytes memory name = "test-commit-twice";
        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));
        IKinoAccountCommittable(address(mintedTba)).commit(commit);
        vm.expectRevert();
        IKinoAccountCommittable(address(mintedTba)).commit(commit);
    }

    function testCommitExpired() public {
        bytes memory name = "test-commit-expired";
        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));

        IKinoAccountCommittable(address(mintedTba)).commit(commit);
        // Fast forward time
        vm.warp(block.timestamp + 6 minutes);
        IKinoAccountCommittable(address(mintedTba)).commit(commit);
    }

    function testMintWithValidCommit() public {
        bytes memory name = "test-mint-valid";
        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));
        IKinoAccountCommittable(address(mintedTba)).commit(commit);
        vm.warp(block.timestamp + 16 seconds);
        IKinoAccountMinter(mintedTba).mint(address(this), name, hex"", basicKinoAccountImpl);
    }

    function testMintWithWrongAddress() public {
        bytes memory name = "test-mint";
        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));
        IKinoAccountCommittable(address(mintedTba)).commit(commit);
        vm.prank(address(1));
        vm.expectRevert();
        IKinoAccountMinter(mintedTba).mint(address(this), name, hex"", basicKinoAccountImpl);
    }

    function testMintWithExpiredCommit() public {
        bytes memory name = "test-mint-expired";
        bytes32 commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));
        IKinoAccountCommittable(address(mintedTba)).commit(commit);

        // Fast forward time
        vm.warp(block.timestamp + 6 minutes);
        vm.expectRevert();
        IKinoAccountMinter(mintedTba).mint(address(this), name, hex"", basicKinoAccountImpl);
    }

    function testGetCommitHash() public view {
        bytes memory name = "test-name";

        bytes32 expectedCommit = keccak256(abi.encode(name, address(this)));
        bytes32 actualCommit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, address(this));

        assertEq(actualCommit, expectedCommit, "getCommitHash should return the correct commit");
    }

    function testMaxCommitAge() public view {
        uint256 expectedMaxCommitAge = 5 minutes;
        uint256 actualMaxCommitAge = KinoAccountCommitMinter(payable(address(mintedTba))).maxCommitAge();

        assertEq(actualMaxCommitAge, expectedMaxCommitAge, "maxCommitAge should be 5 minutes");
    }

    function testFrontRun() public {
        bytes memory name = "i-am-alice";
        address alice = address(42);
        address frank = address(1337);
        bytes32 commitHash = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, alice);
        vm.prank(alice);
        IKinoAccountCommittable(address(mintedTba)).commit(commitHash);
        // Alice can mint the name after 15 seconds
        vm.warp(block.timestamp + 16 seconds);
        // At this point, the mint transaction from Alice is in the mempool.
        // Frank can see it, and create his own transactions based on the the name, which is present in Alice's calldata.
        vm.prank(frank);
        vm.expectRevert();
        IKinoAccountCommittable(address(mintedTba)).commit(commitHash);
        vm.prank(alice);
        IKinoAccountMinter(mintedTba).mint(alice, name, hex"", basicKinoAccountImpl);
    }

    function testFrontRun2() public {
        bytes memory name = "i-am-alice";
        address alice = address(42);
        address frank = address(1337);
        bytes32 alice_commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, alice);
        vm.prank(alice);
        IKinoAccountCommittable(address(mintedTba)).commit(alice_commit);
        vm.warp(block.timestamp + 1 minutes);
        // At this point, the mint transaction from Alice is in the mempool.
        // Frank can see it, and create his own transactions based on the the name, which is present in Alice's calldata.
        bytes32 frank_commit = IKinoAccountCommittable(address(mintedTba)).getCommitHash(name, frank);
        vm.prank(frank);
        IKinoAccountCommittable(address(mintedTba)).commit(frank_commit);
        vm.expectRevert();
        vm.prank(frank);
        IKinoAccountMinter(mintedTba).mint(frank, name, hex"", basicKinoAccountImpl);
        vm.prank(alice);
        IKinoAccountMinter(mintedTba).mint(alice, name, hex"", basicKinoAccountImpl);
    }
}
