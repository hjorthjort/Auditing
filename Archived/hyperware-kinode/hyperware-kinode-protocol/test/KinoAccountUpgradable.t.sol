// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {console} from "forge-std-1.9.4/src/console.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable-5.1.0/proxy/utils/UUPSUpgradeable.sol";
import {IERC721} from "@openzeppelin-contracts-5.1.0/token/ERC721/IERC721.sol";

import {SystemDeployment} from "./SystemDeployment.t.sol";
import {TokenBoundMech} from "../src/account/mech/TokenBoundMech.sol";
import {Kimap} from "../src/kimap/Kimap.sol";
import {IKimap} from "../src/interfaces/IKimap.sol";
import {KinoAccountUpgradable} from "../src/account/KinoAccountUpgradable.sol";
import {UpgradeTest} from "./utils/UpgradeTest.sol";
import {ERC721TokenBoundMech} from "../src/account/mech/ERC721TokenBoundMech.sol";

contract KinoAccountUpgradableTest is SystemDeployment {
    Kimap internal kimap;
    address internal upgradableImpl;
    UpgradeTest internal toUpdate;
    address internal owner = address(0x1);
    address internal safe = address(0x255);
    bytes internal initCallData;

    address internal upgradableTba;

    function setUp() public {
        kimap = deployKimap(safe);

        // Deploy KinoAccountUpgradable implementation
        upgradableImpl = address(new KinoAccountUpgradable());
        initCallData = abi.encodeWithSelector(KinoAccountUpgradable.initialize.selector);

        // mint .test
        vm.prank(safe);
        (address mintedTbaAddress,) = callMint(kimap, address(this), zeroTba, "test", initCallData, upgradableImpl);
        upgradableTba = mintedTbaAddress;
        toUpdate = new UpgradeTest();
    }

    function testInitialize() public {
        // Test initializing again should revert
        vm.expectRevert();
        KinoAccountUpgradable(payable(upgradableTba)).initialize();
    }

    function testUpgradeByNonOperator() public {
        // Test upgrade by non-operator should fail
        vm.prank(owner);
        vm.expectRevert();
        UUPSUpgradeable(upgradableTba).upgradeToAndCall(address(toUpdate), hex"");
    }

    function testUpgradeByOperator() public {
        // Test upgrade by operator should succeed
        UUPSUpgradeable(upgradableTba).upgradeToAndCall(address(toUpdate), hex"");
        assertTrue(UpgradeTest(upgradableTba).success(), "Upgrade failed");
    }

    function testSafeTransferFromAndUpgrade() public {
        address transferTo = address(0x2);
        (, address tokenContract, uint256 tokenId) = TokenBoundMech(payable(upgradableTba)).token();

        // Transfer ownership
        IERC721(tokenContract).safeTransferFrom(address(this), transferTo, tokenId);

        // Upgrade attempt by old owner should fail
        vm.expectRevert();
        UUPSUpgradeable(upgradableTba).upgradeToAndCall(address(toUpdate), hex"");

        // Upgrade by new owner should succeed
        vm.prank(transferTo);
        UUPSUpgradeable(upgradableTba).upgradeToAndCall(address(toUpdate), hex"");
        assertTrue(UpgradeTest(upgradableTba).success(), "Upgrade after transfer failed");
    }

    function testZeroAddressUpgrade() public {
        // Test upgrade to zero address implementation should fail
        vm.expectRevert();
        UUPSUpgradeable(upgradableTba).upgradeToAndCall(address(0), hex"");
    }

    function testUpgradeWithInvalidCalldata() public {
        // Test upgrade with invalid calldata
        vm.expectRevert();
        UUPSUpgradeable(upgradableTba).upgradeToAndCall(address(toUpdate), hex"1234");
    }
}
