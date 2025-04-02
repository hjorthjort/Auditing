// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {console} from "forge-std-1.9.4/src/console.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-5.1.0/proxy/utils/UUPSUpgradeable.sol";
import {IERC721} from "@openzeppelin-contracts-5.1.0/token/ERC721/IERC721.sol";
import {MessageHashUtils} from "@openzeppelin-contracts-5.1.0/utils/cryptography/MessageHashUtils.sol";

import {SystemDeployment} from "./SystemDeployment.t.sol";
import {TokenBoundMech} from "../src/account/mech/TokenBoundMech.sol";
import {Kimap} from "../src/kimap/Kimap.sol";
import {IKimap} from "../src/interfaces/IKimap.sol";
import {KinoAccountMinter} from "../src/account/KinoAccountMinter.sol";
import {IKinoAccountMinter} from "../src/interfaces/IKinoAccountMinter.sol";
import {UpgradeTest} from "./utils/UpgradeTest.sol";
import {KinoAccount} from "../src/account/KinoAccount.sol";

contract KinoAccountMinterTest is SystemDeployment {
    Kimap internal kimap;
    address internal basicKinoAccountImpl;
    UpgradeTest internal toUpdate;
    address internal owner = address(0x1);
    address internal safe = address(0x255);
    address internal minterImpl;
    bytes internal initCallData;

    IKinoAccountMinter internal mintedTba;

    function setUp() public {
        kimap = deployKimap(safe);

        // Deploy default KinoAccount implementation
        basicKinoAccountImpl = address(new KinoAccount());

        // Deploy KinoAccountMinter implementation
        minterImpl = address(new KinoAccountMinter(address(kimap)));
        initCallData = abi.encodeWithSelector(IKinoAccountMinter.initialize.selector);

        // mint .test
        vm.prank(safe);
        (address mintedTbaAddress,) = callMint(kimap, address(this), zeroTba, "test", initCallData, minterImpl);
        mintedTba = IKinoAccountMinter(mintedTbaAddress);
        toUpdate = new UpgradeTest();
    }

    function testZeroTbaDirectMint() public {
        vm.prank(safe);
        vm.expectRevert();
        // TLZ Mint should be done only from execute
        IKinoAccountMinter(zeroTba).mint(safe, "sub-entry-1", hex"", basicKinoAccountImpl);
    }

    function testMint() public {
        address to = address(0x1);
        address tba = mintedTba.mint(to, "sub-entry-1", hex"", basicKinoAccountImpl);
        checkMintCall(tba, "sub-entry-1.test");
    }

    function testZeroLenMint() public {
        address to = address(0x1);
        vm.expectRevert(IKimap.LabelTooShort.selector);
        mintedTba.mint(to, "", hex"", basicKinoAccountImpl);
    }

    function testMaxLenMint() public {
        address to = address(0x1);
        vm.expectRevert(IKimap.LabelTooLong.selector);
        mintedTba.mint(
            to, "0123456789012345678901234567890123456789012345678901234567890123456789", hex"", basicKinoAccountImpl
        );
    }

    function testZeroToMint() public {
        address to = address(0);
        vm.expectRevert();
        mintedTba.mint(to, "sub-entry-1", hex"", basicKinoAccountImpl);
    }

    function testSubMint() public {
        address to = address(0x1);
        address tba1 = mintedTba.mint(to, "sub-entry-1", hex"", minterImpl);

        vm.prank(to);
        (address subdomainMintedTbaAddress,) = callMint(kimap, to, tba1, "subtest", initCallData, minterImpl);
        checkMintCall(subdomainMintedTbaAddress, "subtest.sub-entry-1.test");
    }

    function testUpgrade() public {
        address to = address(0x1);
        mintedTba.mint(to, "sub-entry-1", hex"", basicKinoAccountImpl);
        vm.prank(to);
        vm.expectRevert();
        UUPSUpgradeable(address(mintedTba)).upgradeToAndCall(address(toUpdate), hex"");

        UUPSUpgradeable(address(mintedTba)).upgradeToAndCall(address(toUpdate), hex"");
        assertTrue(UpgradeTest(address(mintedTba)).success(), "Upgrade failed");
    }

    function testSubUpgrade() public {
        address to = address(0x1);
        address tba1 = mintedTba.mint(to, "sub-entry-1", hex"", minterImpl);
        vm.prank(to);
        (address subdomainMintedTbaAddress,) = callMint(kimap, to, tba1, "subtest", initCallData, minterImpl);

        vm.prank(to);
        UUPSUpgradeable(subdomainMintedTbaAddress).upgradeToAndCall(address(toUpdate), hex"");
        assertTrue(UpgradeTest(address(subdomainMintedTbaAddress)).success(), "Upgrade failed");
    }

    function testSafeTransferFrom() public {
        address transferTo = address(0x2);
        (, address tokenContract, uint256 tokenId) = TokenBoundMech(payable(address(mintedTba))).token();
        IERC721(tokenContract).safeTransferFrom(address(this), transferTo, tokenId);

        vm.expectRevert();
        UUPSUpgradeable(address(mintedTba)).upgradeToAndCall(address(toUpdate), hex"");

        vm.prank(transferTo);
        UUPSUpgradeable(address(mintedTba)).upgradeToAndCall(address(toUpdate), hex"");
        assertTrue(UpgradeTest(address(mintedTba)).success(), "Upgrade failed");
    }

    function testMintBySignaturePositive() public {
        (address signer, uint256 signerKey) = makeAddrAndKey("signer");
        bytes32 message = mintedTba.getMessage(safe, "sub-entry-1", hex"", basicKinoAccountImpl, signer);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, MessageHashUtils.toEthSignedMessageHash(message));

        vm.prank(safe);
        address tba = mintedTba.mintBySignature(
            safe, "sub-entry-1", hex"", basicKinoAccountImpl, IKinoAccountMinter.Signature(v, r, s, signer)
        );

        (, address tokenContract, uint256 tokenId) = TokenBoundMech(payable(address(tba))).token();
        assertTrue(IERC721(tokenContract).ownerOf(tokenId) == safe, "Mint failed");
    }

    function testMintBySignatureNegative() public {
        (address signer, uint256 signerKey) = makeAddrAndKey("signer");
        bytes32 message = mintedTba.getMessage(signer, "sub-entry-1", hex"", basicKinoAccountImpl, signer);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, MessageHashUtils.toEthSignedMessageHash(message));
        vm.prank(safe);
        vm.expectRevert();
        mintedTba.mintBySignature(
            signer, "sub-entry-1", hex"", basicKinoAccountImpl, IKinoAccountMinter.Signature(v, r, s, safe)
        );
    }
}
