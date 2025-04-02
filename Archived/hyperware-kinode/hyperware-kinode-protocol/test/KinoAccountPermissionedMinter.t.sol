// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {SystemDeployment} from "./SystemDeployment.t.sol";
import {Kimap} from "../src/kimap/Kimap.sol";
import {KinoAccountPermissionedMinter} from "../src/account/KinoAccountPermissionedMinter.sol";
import {IKimap} from "../src/interfaces/IKimap.sol";
import {IKinoAccountMinter} from "../src/interfaces/IKinoAccountMinter.sol";
import {IKinoAccountPermissioned} from "../src/interfaces/IKinoAccountPermissioned.sol";
import {KinoAccountMinter} from "../src/account/KinoAccountMinter.sol";
import {KinoAccount} from "../src/account/KinoAccount.sol";

contract KinoAccountPermissionedMinterTest is SystemDeployment {
    Kimap internal kimap;
    KinoAccountPermissionedMinter internal minterImpl;
    address internal basicKinoAccountImpl;
    address internal owner = address(0x1);
    address internal safe = address(0x255);
    address internal toAuth = address(0x123);
    IKinoAccountPermissioned internal mintedTba;
    bytes32 internal minterRole;

    function setUp() public {
        kimap = deployKimap(address(this));
        // Deploy default KinoAccount implementation
        basicKinoAccountImpl = address(new KinoAccount());

        // Deploy KinoAccountPermissionedMinter implementation
        minterImpl = new KinoAccountPermissionedMinter(address(kimap));
        (address mintedTbaAddress,) = callMint(
            kimap,
            address(this),
            zeroTba,
            "test",
            abi.encodeWithSelector(IKinoAccountMinter.initialize.selector),
            address(minterImpl)
        );
        mintedTba = IKinoAccountPermissioned(mintedTbaAddress);
    }

    function testAuth() public {
        assertEq(mintedTba.allowance(toAuth), 0);
        mintedTba.auth(toAuth, 5);
        assertEq(mintedTba.allowance(toAuth), 5);
    }

    function testAuthNotOwner() public {
        vm.startPrank(toAuth);
        vm.expectRevert();
        mintedTba.auth(toAuth, 5);
    }

    function testDeauth() public {
        mintedTba.auth(toAuth, 1);
        assertEq(mintedTba.allowance(toAuth), 1);
        mintedTba.deauth(toAuth);
        assertEq(mintedTba.allowance(toAuth), 0);
    }

    function testDeauthNotOperator() public {
        vm.startPrank(toAuth);
        vm.expectRevert();
        mintedTba.deauth(toAuth);
        vm.stopPrank();
    }

    function testUnauthorizedMint() public {
        vm.expectRevert();
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-1", hex"", basicKinoAccountImpl);
    }

    function testAuthorizedMint() public {
        mintedTba.auth(toAuth, 1);
        vm.prank(toAuth);
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-1", hex"", basicKinoAccountImpl);

        assertEq(mintedTba.allowance(toAuth), 0);
    }

    function testMintMultiple() public {
        mintedTba.auth(toAuth, 5);

        vm.startPrank(toAuth);
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-1", hex"", basicKinoAccountImpl);
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-2", hex"", basicKinoAccountImpl);
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-3", hex"", basicKinoAccountImpl);
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-4", hex"", basicKinoAccountImpl);
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-5", hex"", basicKinoAccountImpl);
        vm.stopPrank();

        assertEq(mintedTba.allowance(toAuth), 0);
    }

    function testMintBeyondAllowance() public {
        mintedTba.auth(toAuth, 1);

        vm.startPrank(toAuth);
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-1", hex"", basicKinoAccountImpl);

        vm.expectRevert();
        IKinoAccountMinter(address(mintedTba)).mint(address(this), "sub-entry-2", hex"", basicKinoAccountImpl);
        vm.stopPrank();
    }

    function testInitializeOnlyOnce() public {
        vm.expectRevert();
        IKinoAccountMinter(address(mintedTba)).initialize();
    }

    function testAuthMultiple() public {
        address[] memory toAuths = new address[](3);
        toAuths[0] = address(0x123);
        toAuths[1] = address(0x456);
        toAuths[2] = address(0x789);
        for (uint256 i = 0; i < toAuths.length; i++) {
            mintedTba.auth(toAuth, 1);
            assertEq(mintedTba.allowance(toAuth), 1);
        }
    }

    function testDeauthMultiple() public {
        address[] memory toAuths = new address[](3);
        toAuths[0] = address(0x123);
        toAuths[1] = address(0x456);
        toAuths[2] = address(0x789);
        for (uint256 i = 0; i < toAuths.length; i++) {
            mintedTba.auth(toAuth, 1);
            assertEq(mintedTba.allowance(toAuth), 1);
        }
        for (uint256 i = 0; i < toAuths.length; i++) {
            mintedTba.deauth(toAuth);
            assertEq(mintedTba.allowance(toAuth), 0);
        }
    }
}
