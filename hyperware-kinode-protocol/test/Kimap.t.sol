// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {IERC721Errors} from "@openzeppelin-contracts-5.1.0/interfaces/draft-IERC6093.sol";
import {IERC165} from "@openzeppelin-contracts-5.1.0/utils/introspection/IERC165.sol";
import {ERC1967Proxy} from "@openzeppelin-contracts-5.1.0/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC721} from "@openzeppelin-contracts-5.1.0/token/ERC721/IERC721.sol";
import {ERC6551AccountLib} from "erc6551-reference-0.3.1/src/lib/ERC6551AccountLib.sol";
import {console} from "forge-std-1.9.4/src/console.sol";

import {SystemDeployment} from "./SystemDeployment.t.sol";
import {UpgradeTest} from "./utils/UpgradeTest.sol";
import {KinoAccountGeneTester} from "./utils/KinoAccountGeneTester.sol";
import {ERC721TokenboundAccountSpoof} from "./utils/ERC721TokenboundAccountSpoof.sol";
import {KinoAccountProxy} from "../src/account/KinoAccountProxy.sol";
import {KinoAccountMinter} from "../src/account/KinoAccountMinter.sol";
import {NameEncoder} from "../src/utils/NameEncoder.sol";
import {IMech} from "../src/interfaces/IMech.sol";
import {Kimap} from "../src/kimap/Kimap.sol";
import {IKimap} from "../src/interfaces/IKimap.sol";
import {IMulticall} from "../src/interfaces/IMulticall.sol";
import {Receiver} from "../src/account/mech/Receiver.sol";

contract KimapTest is SystemDeployment {
    Kimap public kimap;
    address public kinoAccount;
    address public kinoAccountProxy;
    address public kinoAccountSpoof;
    address public safe = address(this);

    function setUp() public {
        kinoAccountSpoof = address(new ERC721TokenboundAccountSpoof());

        kimap = deployKimap(safe);
        kinoAccount = address(new KinoAccountMinter(address(kimap)));
        kinoAccountProxy = address(new KinoAccountProxy(address(kimap)));
    }

    function testKimapDeploy() public view {
        address zeroOwner = kimap.ownerOf(0);
        assertEq(zeroOwner, safe, "zeroth node is not assigned to user");
    }

    function callMint(address tba, bytes memory name, address implementation)
        public
        returns (address mintedTba, uint256 mintedNode)
    {
        bytes memory data = IMech(tba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, name, hex"", implementation), 0
        );

        (mintedTba) = abi.decode(data, (address));

        (,, mintedNode) = ERC6551AccountLib.token(mintedTba);
    }

    function callFact(address tba, bytes memory fact, bytes memory _data) public returns (bytes32 node) {
        bytes memory data =
            IMech(tba).execute(address(kimap), 0, abi.encodeWithSignature("fact(bytes,bytes)", fact, _data), 0);

        (node) = abi.decode(data, (bytes32));
    }

    function callNote(address tba, bytes memory note, bytes memory _data) public returns (bytes32 node) {
        bytes memory data =
            IMech(tba).execute(address(kimap), 0, abi.encodeWithSelector(IKimap.note.selector, note, _data), 0);

        (node) = abi.decode(data, (bytes32));
    }

    function receiverTest() public pure {
        assertEq(Receiver.onERC1155Received.selector, bytes4(0xf23a6e61));
        assertEq(Receiver.onERC1155BatchReceived.selector, bytes4(0xbc197c81));
        assertEq(Receiver.onERC721Received.selector, bytes4(0x150b7a02));
    }

    function testMint() public {
        bytes memory label = "os";

        (, bytes32 encodedOs) = NameEncoder.dnsEncodeName(string(label));

        (address dotOsTba, uint256 dotOsTokenId) = callMint(zeroTba, label, kinoAccount);

        assertEq(dotOsTokenId, uint256(encodedOs), "!token id");

        assertEq(kimap.ownerOf(dotOsTokenId), safe, "!owner");

        assertEq(kimap.tbaOf(encodedOs), dotOsTba, "!tba");

        assertTrue(IERC165(dotOsTba).supportsInterface(type(IMech).interfaceId), "!account");
    }

    function testMintCallableOncePerName() public {
        callMint(zeroTba, "os", kinoAccount);

        vm.expectRevert(IKimap.NameAlreadyExists.selector);

        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "os", hex"", kinoAccount), 0
        );
    }

    function testMintWithInitialization() public {
        IMulticall.Call[] memory calls = new IMulticall.Call[](3);

        calls[0] = IMulticall.Call(
            address(kimap), abi.encodeWithSelector(Kimap.note.selector, "~ip", abi.encodePacked(type(uint256).max))
        );

        calls[1] = IMulticall.Call(
            address(kimap), abi.encodeWithSelector(Kimap.note.selector, "~ws-port", abi.encodePacked(type(uint16).max))
        );

        calls[2] = IMulticall.Call(
            address(kimap), abi.encodeWithSelector(Kimap.note.selector, "~net-key", abi.encodePacked(type(uint256).max))
        );

        bytes memory aggregateCall = abi.encodeWithSelector(IMulticall.aggregate.selector, calls);

        bytes memory initCalls = abi.encodeWithSelector(IMech.execute.selector, address(MULTICALL), 0, aggregateCall, 1);

        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "os", initCalls, kinoAccount), 0
        );

        bytes32 noteHash;
        address tba;
        address owner;
        bytes memory noteData;

        (, noteHash) = NameEncoder.dnsEncodeName("~ip.os");
        (tba, owner, noteData) = kimap.get(noteHash);
        assertEq(tba, address(0), "tba of ~ip.os should be zero");
        assertEq(owner, address(0), "owner of ~ip.os should be zero");
        assertEq(noteData, abi.encodePacked(type(uint256).max), "wrong ~ip.os data");

        (, noteHash) = NameEncoder.dnsEncodeName("~ws-port.os");
        (tba, owner, noteData) = kimap.get(noteHash);
        assertEq(tba, address(0), "tba of ~ws-port.os should be zero");
        assertEq(owner, address(0), "owner of ~ws-port.os should be zero");
        assertEq(noteData, abi.encodePacked(type(uint16).max), "wrong ~ws-port.os data");

        (, noteHash) = NameEncoder.dnsEncodeName("~net-key.os");
        (tba, owner, noteData) = kimap.get(noteHash);
        assertEq(tba, address(0), "tba of ~net-key.os should be zero");
        assertEq(owner, address(0), "owner of ~net-key.os should be zero");
        assertEq(noteData, abi.encodePacked(type(uint256).max), "wrong ~net-key.os data");
    }

    function testNote() public {
        // mint .os
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        // mint crashtest.os
        (address crashTestTba, uint256 crashTestToken) = callMint(dotOsTba, "crashtest", kinoAccount);

        (, bytes32 namehash) = NameEncoder.dnsEncodeName("~note.crashtest.os");

        vm.expectEmit();
        emit IKimap.Note(bytes32(crashTestToken), namehash, "~note", "~note", "info");

        // mint ~note.crashtest.os
        bytes32 noteNamehash = callNote(crashTestTba, "~note", "info");

        assertEq(noteNamehash, namehash, "namehash mismatch");

        (address tba, address owner, bytes memory data) = kimap.get(noteNamehash);

        assertEq(keccak256(data), keccak256(bytes("info")), "data mismatch");
        assertEq(tba, address(0), "note tba should be zero");
        assertEq(owner, address(0), "note owner should be zero");
    }

    function testNameNodeMustNotHaveTildeOrBang() public {
        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "~os", hex"", kinoAccount), 0
        );

        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "!os", hex"", kinoAccount), 0
        );
    }

    function testNoteWithInvalidName() public {
        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        // exclamation mark is not allowed
        IMech(zeroTba).execute(
            address(kimap),
            0,
            abi.encodeWithSelector(Kimap.mint.selector, safe, "hey-this-is-an-invalid-name!!!", hex"", kinoAccount),
            0
        );

        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        // tilde is not allowed in a name
        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "hey~", hex"", kinoAccount), 0
        );

        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        // caret is not allowed
        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "hey^", hex"", kinoAccount), 0
        );

        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        // uppercase letters are not allowed
        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "Hello", hex"", kinoAccount), 0
        );

        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        // spaces are not allowed
        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "hey there", hex"", kinoAccount), 0
        );

        vm.expectRevert(IKimap.InvalidLabelCharacter.selector);

        // dots are not allowed
        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSelector(Kimap.mint.selector, safe, "hey.there", hex"", kinoAccount), 0
        );
    }

    function testNoteWith32BytesOfData() public {
        bytes memory data = abi.encodePacked(bytes32(type(uint256).max));

        (, bytes32 namehash) = NameEncoder.dnsEncodeName("os");
        (, bytes32 notehash) = NameEncoder.dnsEncodeName("~note.os");

        // mint .os
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        vm.expectEmit();
        emit IKimap.Note(namehash, notehash, "~note", "~note", data);

        // mint ~note.os with 32 bytes of data
        callNote(dotOsTba, "~note", data);

        (,, bytes memory noteData) = kimap.get(notehash);
        assertEq(noteData, data, "data should match");
    }

    function testNoteWith48BytesOfData() public {
        bytes memory data = abi.encodePacked(bytes32(type(uint256).max), bytes16(type(uint128).max));

        (, bytes32 namehash) = NameEncoder.dnsEncodeName("os");
        (, bytes32 notehash) = NameEncoder.dnsEncodeName("~note.os");

        // mint .os
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        vm.expectEmit();
        emit IKimap.Note(namehash, notehash, "~note", "~note", data);

        // mint ~note.os with 48 bytes of data
        callNote(dotOsTba, "~note", data);

        (,, bytes memory noteData) = kimap.get(notehash);
        assertEq(noteData, data, "data should match");
    }

    function testNoteUpdates() public {
        bytes memory initialData = abi.encodePacked("hello there");
        bytes memory data;

        (, bytes32 namehash) = NameEncoder.dnsEncodeName("os");
        (, bytes32 notehash) = NameEncoder.dnsEncodeName("~note.os");

        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        vm.expectEmit();
        emit IKimap.Note(namehash, notehash, "~note", "~note", initialData);

        // mint ~note.os with initial data
        callNote(dotOsTba, "~note", initialData);

        (,, data) = kimap.get(notehash);

        assertEq(data, initialData, "data should be initialData");

        bytes memory newData = abi.encodePacked(bytes32(type(uint256).max), bytes16(type(uint128).max));

        vm.expectEmit();
        emit IKimap.Note(namehash, notehash, "~note", "~note", newData);

        // update ~note.os with new data
        callNote(dotOsTba, "~note", newData);

        (,, data) = kimap.get(notehash);

        assertEq(data, newData, "data should be newData");

        vm.expectEmit();
        emit IKimap.Note(namehash, notehash, "~note", "~note", "");

        // update ~note.os to empty data
        callNote(dotOsTba, "~note", hex"");

        (,, data) = kimap.get(notehash);

        assertEq(data, hex"", "data should be empty");
    }

    function testNoteMustHaveTilde() public {
        vm.expectRevert(IKimap.NoteMustBeginWithTilde.selector);

        IMech(zeroTba).execute(address(kimap), 0, abi.encodeWithSelector(IKimap.note.selector, "note", hex""), 0);
    }

    function testOwnerOf() public {
        // mint .os
        (address dotOsTba, uint256 dotOsToken) = callMint(zeroTba, "os", kinoAccount);

        // mint ~note.os with "info" as data
        bytes32 noteDotOsNode = callNote(dotOsTba, "~note", "info");

        address owner = kimap.ownerOf(dotOsToken);

        assertEq(owner, safe, "this should be owner of dotOsTba");

        // ownerOf should revert on note nodes
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, uint256(noteDotOsNode)));
        owner = kimap.ownerOf(uint256(noteDotOsNode));

        (, bytes32 subDotOsNode) = NameEncoder.dnsEncodeName("sub.os");

        // ownerOf should revert if name doesn't exist
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, uint256(subDotOsNode)));
        owner = kimap.ownerOf(uint256(subDotOsNode));

        // mint sub.os
        callMint(dotOsTba, "sub", kinoAccount);

        owner = kimap.ownerOf(uint256(subDotOsNode));

        assertEq(owner, safe, "owner of name just minted should be this");
    }

    function testTbaOf() public {
        (address dotOsTba, uint256 dotOsToken) = callMint(zeroTba, "os", kinoAccount);

        bytes32 noteDotOsNode = callNote(dotOsTba, "~note", "info");

        address tba = kimap.tbaOf(bytes32(dotOsToken));

        assertEq(tba, dotOsTba, "dotOsTba should be tba of dotOsToken");

        tba = kimap.tbaOf(noteDotOsNode);

        assertEq(tba, address(0), "non name nodes owner should be 0");

        (, bytes32 subDotOsNode) = NameEncoder.dnsEncodeName("sub.os");

        tba = kimap.tbaOf(subDotOsNode);

        assertEq(tba, address(0), "tba of name that doesn't exist should be 0");

        (address subDotOsTba,) = callMint(dotOsTba, "sub", kinoAccount);

        tba = kimap.tbaOf(subDotOsNode);

        assertEq(tba, subDotOsTba, "incorrect tba of name just minted");
    }

    function testFactMayNotChange() public {
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        bytes memory data =
            IMech(dotOsTba).execute(address(kimap), 0, abi.encodeWithSelector(IKimap.fact.selector, "!fact", "data"), 0);

        bytes32 factnode = abi.decode(data, (bytes32));

        (,, bytes memory noted) = kimap.get(factnode);

        assertEq(keccak256(noted), keccak256("data"), "fact should be written");

        vm.expectRevert(abi.encodeWithSelector(IKimap.FactAlreadyExists.selector));

        IMech(dotOsTba).execute(address(kimap), 0, abi.encodeWithSelector(IKimap.fact.selector, "!fact", ""), 0);

        (,, noted) = kimap.get(factnode);

        assertEq(keccak256(noted), keccak256("data"), "fact should be the same");
    }

    function testFactMustHaveBang() public {
        vm.expectRevert(abi.encodeWithSelector(IKimap.FactMustBeginWithBang.selector));

        IMech(zeroTba).execute(address(kimap), 0, abi.encodeWithSignature("fact(bytes,bytes)", "fact", hex""), 0);
    }

    function testTransferFrom() public {
        // mint .os
        (, uint256 dotOsTokenId) = callMint(zeroTba, "os", kinoAccount);

        // transfer .os to address(1)
        kimap.transferFrom(safe, address(1), dotOsTokenId);

        address owner = kimap.ownerOf(dotOsTokenId);
        assertEq(owner, address(1), "owner should be 1");
    }

    function testSpoofProof() public {
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        (, uint256 crashTestToken) = callMint(dotOsTba, "crashtest", kinoAccount);

        address spoof = ERC6551_REGISTRY.createAccount(
            kinoAccountProxy, bytes32(crashTestToken), block.chainid, address(kimap), crashTestToken
        );

        vm.expectRevert();
        KinoAccountProxy(payable(spoof)).initialize(kinoAccountSpoof, "");
    }

    function testSpoofProofBeforeMinting() public {
        callMint(zeroTba, "os", kinoAccount);

        (, bytes32 namehashed) = NameEncoder.dnsEncodeName("crashtest.os");

        address spoof = ERC6551_REGISTRY.createAccount(
            kinoAccountProxy, namehashed, block.chainid, address(kimap), uint256(namehashed)
        );

        vm.expectRevert();
        KinoAccountProxy(payable(spoof)).initialize(kinoAccountSpoof, "");
    }

    function testGene() public {
        KinoAccountGeneTester geneTestImpl = new KinoAccountGeneTester(address(kimap), true);

        // mint .os
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        // set gene of .os
        IMech(dotOsTba).execute(
            address(kimap), 0, abi.encodeWithSelector(IKimap.gene.selector, address(geneTestImpl)), 0
        );

        // mint sub.os with kinoAccount, but gene should set it to geneTestImpl
        (address subTba,) = callMint(dotOsTba, "sub", kinoAccount);

        assertTrue(KinoAccountGeneTester(payable(subTba)).gene(), "sub.os tba's custom fn gene() should return true");

        // mint sub.sub.os with kinoAccount, should inherit gene from sub.os
        (address subSubTba,) = callMint(subTba, "sub", kinoAccount);

        assertTrue(KinoAccountGeneTester(payable(subSubTba)).gene(), "subsubgene tba's gene() should return true");
    }

    function testKimapCreate2Upgrade() public {
        bool success;

        address upgradeTestKimapImpl = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), CREATE2, keccak256("upgrade"), keccak256(type(Kimap).creationCode)
                        )
                    )
                )
            )
        );

        (success,) = CREATE2.call(abi.encodePacked(keccak256("upgrade"), type(Kimap).creationCode));

        assertTrue(success, "upgrade should be successful");

        Kimap(
            payable(
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    bytes1(0xff),
                                    CREATE2,
                                    keccak256("upgrade"),
                                    keccak256(
                                        abi.encodePacked(
                                            type(ERC1967Proxy).creationCode,
                                            abi.encode(
                                                upgradeTestKimapImpl,
                                                abi.encodeWithSelector(Kimap.initialize.selector, safe)
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        );

        (success,) = CREATE2.call(
            abi.encodePacked(
                keccak256("upgrade"),
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(upgradeTestKimapImpl, abi.encodeWithSelector(Kimap.initialize.selector, safe))
                )
            )
        );

        assertTrue(success, "upgrade should be successful");
    }

    function testKimapSafeUpgrade() public {
        address upgradeTo = address(new UpgradeTest());

        // Upgrade by safe
        vm.prank(safe);
        kimap.upgradeToAndCall(upgradeTo, hex"");
        assertTrue(UpgradeTest(address(kimap)).success(), "Safe updgrade failed");

        vm.expectRevert();
        vm.prank(address(1));
        kimap.upgradeToAndCall(address(2), hex"");
    }

    function testKimapZeroTbaUpgrade() public {
        // Omly safe should upgrade
        address upgradeTo = address(new UpgradeTest());

        address zeroTba = kimap.tbaOf(0);

        vm.expectRevert();
        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSignature("upgradeToAndCall(address,bytes)", upgradeTo, hex""), 0
        );
    }

    function testSetApprovalForAll() public {
        address operator = address(0x123);
        kimap.setApprovalForAll(operator, true);
        assertTrue(kimap.isApprovedForAll(safe, operator), "Approval not set correctly");

        kimap.setApprovalForAll(operator, false);
        assertFalse(kimap.isApprovedForAll(safe, operator), "Approval not revoked correctly");
    }

    function testApprove() public {
        (, uint256 dotOsTokenId) = callMint(zeroTba, "os", kinoAccount);
        address approved = address(0x456);

        kimap.approve(approved, dotOsTokenId);
        assertEq(kimap.getApproved(dotOsTokenId), approved, "Approval not set correctly");
    }

    function testSafeTransferFrom() public {
        (, uint256 dotOsTokenId) = callMint(zeroTba, "os", kinoAccount);
        address recipient = address(0x789);

        kimap.safeTransferFrom(safe, recipient, dotOsTokenId);
        assertEq(kimap.ownerOf(dotOsTokenId), recipient, "Token not transferred correctly");
    }

    function testTransferZeroTba() public {
        kimap.safeTransferFrom(safe, address(0x1), 0);
        vm.prank(address(0x1));
        callMint(zeroTba, "os", kinoAccount);
    }

    function testTransferZeroTbaUpgrade() public {
        kimap.safeTransferFrom(safe, address(0x1), 0);
        address upgradeTo = address(new UpgradeTest());
        vm.prank(address(0x1));
        vm.expectRevert();
        IMech(zeroTba).execute(
            address(kimap), 0, abi.encodeWithSignature("upgradeToAndCall(address,bytes)", upgradeTo, hex""), 0
        );
    }

    function testSupportsInterface() public view {
        assertTrue(kimap.supportsInterface(type(IERC721).interfaceId), "Should support ERC721 interface");
        assertTrue(kimap.supportsInterface(type(IERC165).interfaceId), "Should support ERC165 interface");
    }

    function testBalanceOf() public {
        uint256 initialBalance = kimap.balanceOf(safe);
        callMint(zeroTba, "os", kinoAccount);
        uint256 newBalance = kimap.balanceOf(safe);
        assertEq(newBalance, initialBalance + 1, "Balance should increase after minting");
    }

    function testCallGeneTwice() public {
        KinoAccountGeneTester geneTestImpl = new KinoAccountGeneTester(address(kimap), true);
        KinoAccountGeneTester geneTestImpl2 = new KinoAccountGeneTester(address(kimap), false);

        // mint .os
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        // set gene of .os
        IMech(dotOsTba).execute(
            address(kimap), 0, abi.encodeWithSelector(IKimap.gene.selector, address(geneTestImpl)), 0
        );

        // mint sub.os with kinoAccount, but gene should set it to geneTestImpl
        (address subTba,) = callMint(dotOsTba, "sub", kinoAccount);

        // delete gene of .sub
        vm.expectRevert();
        IMech(subTba).execute(
            address(kimap), 0, abi.encodeWithSelector(IKimap.gene.selector, address(geneTestImpl2)), 0
        );
    }

    function testCounterFactual() public {
        (address dotOsTba,) = callMint(zeroTba, "os", kinoAccount);

        (, uint256 crashTestToken) = callMint(dotOsTba, "crashtest", kinoAccount);

        bytes32 namehash = bytes32(uint256(1));

        address proxyAddress = address(new KinoAccountProxy{salt: namehash}(address(this)));

        address bob = makeAddr("bob");
        vm.startPrank(bob);
        address bobProxy = address(new KinoAccountProxy{salt: namehash}(address(this)));
        vm.stopPrank();

        ERC6551_REGISTRY.account(proxyAddress, bytes32(crashTestToken), block.chainid, address(kimap), crashTestToken);
        assertTrue(bobProxy != proxyAddress);
    }
}
