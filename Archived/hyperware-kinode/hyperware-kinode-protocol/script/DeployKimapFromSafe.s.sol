// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {ERC1967Proxy} from "@openzeppelin-contracts-5.1.0/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessControl} from "@openzeppelin-contracts-5.1.0/access/IAccessControl.sol";
import {Script, VmSafe} from "forge-std-1.9.4/src/Script.sol";
import {console} from "forge-std-1.9.4/src/console.sol";

import {NameEncoder} from "../src/utils/NameEncoder.sol";
import {KinoAccount} from "../src/account/KinoAccount.sol";
import {KinoAccount9CharCommitMinter} from "../src/account/KinoAccount9CharCommitMinter.sol";
import {KinoAccountPermissionedMinter} from "../src/account/KinoAccountPermissionedMinter.sol";
import {IKimap} from "../src/interfaces/IKimap.sol";
import {IMech} from "../src/interfaces/IMech.sol";
import {IKinoAccountPermissioned} from "../src/interfaces/IKinoAccountPermissioned.sol";
import {IKinoAccountMinter} from "../src/interfaces/IKinoAccountMinter.sol";
import {IKinoAccountCommittable} from "../src/interfaces/IKinoAccountCommittable.sol";
import {Kimap} from "../src/kimap/Kimap.sol";

/// @dev deployment script set up using kinode safe
/// **must be run with --rpc-url flag**
///
/// this deploys kimap, an upgradable proxy for kimap, the .os TLZ
/// with 9char min and pre-commitment, and the .kino TLZ with admin
/// control.
contract Deployment is Script {
    /// @dev CREATE2 optimismdeployer address
    address CREATE2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    /// @dev Kinode Protocol safe (on base -- deployment will occur on base)
    address SAFE = 0x474Bf74A4f1718BdCD07d9C50B5FE2eA059F40f7;
    /// @dev ERC6551 registry address
    address ERC6551_REGISTRY = 0x000000006551c19487814612e58FE06813775758;
    /// @dev chain id
    uint256 CHAIN_ID = 8453;

    address TEST_EOA = 0x70997970c51812dc3a010c7D01B50E0D17Dc79c9;

    /// @dev "general" salt for deployment -- WILL CHANGE, will also
    /// be overrriden by specific salts for contracts that are getting golfed
    bytes32 salt = keccak256("loacheen");

    function run() public {
        vm.chainId(CHAIN_ID);

        checkERC6551Registry();

        //
        // kimapImpl: the kimap implementation
        //
        bytes memory data = type(Kimap).creationCode;
        console.log("KIMAP_IMPL_INIT_CODE_HASH: ");
        console.logBytes32(keccak256(data));
        // use this for kimapProxy mined addr
        salt = 0xa79889afe57fc960b63d267fd91a3dbad321a7cb57a94c29258a860cbd070038;
        address kimapImpl =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2, salt, keccak256(data))))));
        bytes memory kimapImplDeployData = abi.encodePacked(salt, data);

        //
        // kimapProxy: the kimap proxy
        //
        // set the initialize call to use address(0) as the zeroth TBA implementation to deploy default kino account minter
        // this will result in only the owner of the kimap being able to mint top-level entries.
        //
        // set the owner as the kinode staging safe
        //
        data = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(kimapImpl, abi.encodeWithSelector(Kimap.initialize.selector, SAFE, address(0)))
        );
        console.log("KIMAP_PROXY_INIT_CODE_HASH: ");
        console.logBytes32(keccak256(data));
        // mined for 5 leading zeros
        salt = 0x474bf74a4f1718bdcd07d9c50b5fe2ea059f40f781c837fb8b6a09cf6a610960;
        address kimapProxy =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2, salt, keccak256(data))))));
        bytes memory kimapProxyDeployData = abi.encodePacked(salt, data);

        //
        // kinoAccount9CharCommitMinterImpl: a TBA that allows anyone to mint entries beneath
        // a given name, provided they make a commitment beforehand. the name must also
        // be at least 9 bytes long.
        //
        data = abi.encodePacked(
            type(KinoAccount9CharCommitMinter).creationCode,
            abi.encode(kimapProxy, uint256(15 seconds), uint256(30 minutes))
        );
        console.log("KINO_ACCOUNT_9_CHAR_COMMIT_MINTER_INIT_CODE_HASH: ");
        console.logBytes32(keccak256(data));
        // salt = 0xa79889afe57fc960b63d267fd91a3dbad321a7cb676b867964f6b17d890400c0;
        address kinoAccount9CharCommitMinterImpl =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2, salt, keccak256(data))))));

        bytes memory kinoAccount9CharCommitMinterImplDeployData = abi.encodePacked(salt, data);

        //
        // kinoAccountPermissionedMinterImpl: a TBA that uses an owner and
        // permissioned minters to mint entries beneath a given name.
        //
        data = abi.encodePacked(type(KinoAccountPermissionedMinter).creationCode, abi.encode(kimapProxy));
        console.log("KINO_ACCOUNT_PERMISSIONED_MINTER_INIT_CODE_HASH: ");
        console.logBytes32(keccak256(data));
        // salt = 0xa79889afe57fc960b63d267fd91a3dbad321a7cb12900d83021c56f9af050004;
        address kinoAccountPermissionedMinterImpl =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2, salt, keccak256(data))))));
        bytes memory kinoAccountPermissionedMinterImplDeployData = abi.encodePacked(salt, data);

        //
        // kinoAccountImpl: the trivial TBA implementation
        //
        data = abi.encodePacked(type(KinoAccount).creationCode, abi.encode(kimapProxy));
        console.log("KINO_ACCOUNT_INIT_CODE_HASH: ");
        console.logBytes32(keccak256(data));
        // mined for 5 leading zeros
        salt = 0x474bf74a4f1718bdcd07d9c50b5fe2ea059f40f778ed9ed8f702c07743830e40;
        address kinoAccountImpl =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2, salt, keccak256(data))))));
        bytes memory kinoAccountImplDeployData = abi.encodePacked(salt, data);

        // simulate the deployment of the contracts with CREATE2
        (bool success,) = CREATE2.call(kimapImplDeployData);
        require(success, "kimapImpl deployment failed");
        (success,) = CREATE2.call(kinoAccountImplDeployData);
        require(success, "kinoAccountImpl deployment failed");
        (success,) = CREATE2.call(kimapProxyDeployData);
        require(success, "kimapProxy deployment failed");
        (success,) = CREATE2.call(kinoAccount9CharCommitMinterImplDeployData);
        require(success, "kinoAccount9CharCommitMinterImpl deployment failed");
        (success,) = CREATE2.call(kinoAccountPermissionedMinterImplDeployData);
        require(success, "kinoAccountPermissionedMinterImpl deployment failed");

        console.log("\nTransactions for safe:\n");

        console.log("To deploy kino_account to: ", kinoAccountImpl);
        console.log("Call address ", CREATE2);
        console.log("with calldata: ");
        console.logBytes(kinoAccountImplDeployData);

        console.log("\n\nTo deploy kino_account_9_char_commit_minter to: ", kinoAccount9CharCommitMinterImpl);
        console.log("Call address ", CREATE2);
        console.log("with calldata: ");
        console.logBytes(kinoAccount9CharCommitMinterImplDeployData);

        console.log("\n\nTo deploy kino_account_permissioned_minter to: ", kinoAccountPermissionedMinterImpl);
        console.log("Call address ", CREATE2);
        console.log("with calldata: ");
        console.logBytes(kinoAccountPermissionedMinterImplDeployData);

        console.log("\n\nTo deploy kimap to: ", kimapImpl);
        console.log("Call address ", CREATE2);
        console.log("with calldata: ");
        console.logBytes(kimapImplDeployData);

        console.log("\n\nTo deploy kimapProxy to: ", kimapProxy);
        console.log("Call address ", CREATE2);
        console.log("with calldata: ");
        console.logBytes(kimapProxyDeployData);

        console.log("\n\n================================================");

        (address zeroTba,,) = IKimap(kimapProxy).get(bytes32(0));

        mintDotOs(zeroTba, kimapProxy, kinoAccount9CharCommitMinterImpl, kinoAccountImpl);

        mintDotKino(zeroTba, kimapProxy, kinoAccountPermissionedMinterImpl, kinoAccountImpl);

        console.log("\n\n");
        console.log("********************************");
        console.log("zeroth entry TBA: ", zeroTba);
        console.log("call this contract to mint top-level entries");
        console.log("********************************\n\n");
    }

    function callMint(
        IKimap kimapProxy,
        address to,
        address _tba,
        bytes memory name,
        bytes memory initialization,
        address implementation
    ) public returns (bytes memory data) {
        data = abi.encodeWithSelector(
            IMech.execute.selector,
            address(kimapProxy),
            0,
            abi.encodeWithSelector(IKimap.mint.selector, to, name, initialization, implementation),
            0
        );

        IMech(_tba).execute(
            address(kimapProxy),
            0,
            abi.encodeWithSelector(IKimap.mint.selector, to, name, initialization, implementation),
            0
        );

        return data;
    }

    function mintDotOs(
        address zeroTba,
        address kimapProxy,
        address kinoAccount9CharCommitMinterImpl,
        address kinoAccountImpl
    ) internal {
        vm.startPrank(SAFE);
        bytes memory name = "os";
        bytes32 namehash = IKimap(kimapProxy).leaf("", name);

        bytes memory mintData = callMint(
            IKimap(kimapProxy),
            SAFE,
            zeroTba,
            name,
            abi.encodeWithSelector(IKinoAccountMinter.initialize.selector),
            kinoAccount9CharCommitMinterImpl
        );

        vm.stopPrank();
        (address mintedTbaAddress,,) = IKimap(kimapProxy).get(namehash);

        console.log("\n\nTo mint .os TLZ with 9 char min and pre-commitment:");
        console.log("Call address ", zeroTba);
        console.log("with calldata: ");
        console.logBytes(mintData);
        console.log("\n\n.os TLZ TBA will be: ", mintedTbaAddress);
        console.log("TLZ owner will be the safe: ", SAFE);

        testDotOs(mintedTbaAddress, kimapProxy, kinoAccountImpl);
    }

    function mintDotKino(
        address zeroTba,
        address kimapProxy,
        address kinoAccountPermissionedMinterImpl,
        address kinoAccountImpl
    ) internal {
        vm.startPrank(SAFE);
        bytes memory name = "kino";
        bytes32 namehash = IKimap(kimapProxy).leaf("", name);

        bytes memory mintData = callMint(
            IKimap(kimapProxy),
            SAFE,
            zeroTba,
            name,
            abi.encodeWithSelector(IKinoAccountMinter.initialize.selector),
            kinoAccountPermissionedMinterImpl
        );

        vm.stopPrank();
        (address mintedTbaAddress,,) = IKimap(kimapProxy).get(namehash);

        console.log("\n\nTo mint .kino TLZ with permissioned minter:");
        console.log("Call address ", zeroTba);
        console.log("with calldata: ");
        console.logBytes(mintData);
        console.log("\n\n.kino TLZ TBA will be: ", mintedTbaAddress);
        console.log("TLZ owner will be the safe: ", SAFE);

        testDotKino(mintedTbaAddress, kimapProxy, kinoAccountImpl);
    }

    function checkERC6551Registry() internal view {
        // Check if the ERC6551 registry exists at the expected address
        uint256 codeSize;
        address registryAddress = ERC6551_REGISTRY;
        assembly {
            codeSize := extcodesize(registryAddress)
        }
        require(codeSize > 0, "ERC6551 Registry not deployed at the expected address");

        console.log("ERC6551 Registry verified at address:", registryAddress);
    }

    /// @dev confirm the .os TBA is working as expected by registering a subdomain
    function testDotOs(address dotOsTba, address kimapProxy, address kinoAccountImpl) internal {
        console.log("\n\nTesting .os TBA...");
        bytes memory subname = "testtest123";

        vm.startPrank(TEST_EOA);
        bytes32 commit = IKinoAccountCommittable(address(dotOsTba)).getCommitHash(subname, TEST_EOA);

        console.log("Sending commit call from test EOA");
        IKinoAccountCommittable(address(dotOsTba)).commit(commit);

        console.log("Waiting 16 seconds...");
        vm.warp(block.timestamp + 16 seconds);

        console.log("Sending mint call from test EOA");

        IKinoAccountMinter(dotOsTba).mint(TEST_EOA, subname, hex"", kinoAccountImpl);
        vm.stopPrank();

        (, bytes32 testOsNamehash) = NameEncoder.dnsEncodeName("testtest123.os");
        (address testOsTba,,) = IKimap(kimapProxy).get(testOsNamehash);
        console.log("testtest123.os testOsTba: ", testOsTba);
        console.log("minted testtest123.os successfully");
    }

    /// @dev confirm the .kino TBA is working as expected by registering a subdomain
    function testDotKino(address dotKinoTba, address kimapProxy, address kinoAccountImpl) internal {
        console.log("\n\nTesting .kino TBA...");
        bytes memory subname = "testtest123";

        console.log("Sending auth call from safe");
        vm.startPrank(SAFE);
        IKinoAccountPermissioned(address(dotKinoTba)).auth(TEST_EOA, 1);
        vm.stopPrank();

        console.log("Sending mint call from test EOA");
        vm.startPrank(TEST_EOA);
        IKinoAccountMinter(dotKinoTba).mint(TEST_EOA, subname, hex"", kinoAccountImpl);
        vm.stopPrank();

        (, bytes32 testKinoNamehash) = NameEncoder.dnsEncodeName("testtest123.os");
        (address testOsTba,,) = IKimap(kimapProxy).get(testKinoNamehash);
        console.log("testtest123.kino testOsTba: ", testOsTba);
        console.log("minted testtest123.kino successfully");
    }
}
