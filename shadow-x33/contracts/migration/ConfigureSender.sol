// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {ShadowMessageSender} from "contracts/migration/ShadowMessageSender.sol";
import {console2} from "forge-std/console2.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
contract ConfigureSender is Script {
    // V2 Endpoint address for Fantom
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant EXECUTOR_ADDRESS = 0x2957eBc0D2931270d4a539696514b047756b3056;
    // V2 library addresses for Fantom
    address constant SEND_LIB_ADDRESS = 0xC17BaBeF02a937093363220b0FB57De04A535D5E;
    address constant RECEIVE_LIB_ADDRESS = 0xe1Dd69A2D08dF4eA6a30a91cC061ac70F98aAbe3;
    // Default DVN address
    address constant DEFAULT_DVN = 0xE60A3959Ca23a92BF5aAf992EF837cA7F828628a;
    // chain EIDs
    uint32 constant FANTOM_CHAIN_ID = 30112;
    uint32 constant SONIC_CHAIN_ID = 30332;
    // deployed contracts
    address constant MSIG = 0xCAfc58De1E6A071790eFbB6B83b35397023E1544;
    address constant MESSAGE_SENDER = 0xf047f81EB5D76dcde0C292d783E161f26e885cE8; 
    address constant MESSAGE_RECEIVER = 0x8Cceb02D14F605850A2aaD9EB705092717047E04;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // delegate to ourself (deployer)
        ShadowMessageSender(MESSAGE_SENDER).setDelegate(vm.addr(deployerPrivateKey));
        // update setPeer to include the peer address (using destination chain ID)
        ShadowMessageSender(MESSAGE_SENDER).setPeer(SONIC_CHAIN_ID, bytes32(uint256(uint160(MESSAGE_RECEIVER))));
        // configure LayerZero settings
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);
        // set the libraries first
        endpoint.setSendLibrary(
            MESSAGE_SENDER,
            SONIC_CHAIN_ID,
            SEND_LIB_ADDRESS
        );
        // executor config (using destination chain ID)
        bytes memory executorConfig = abi.encode(
            uint32(500_000), // maxMessageSize
            EXECUTOR_ADDRESS
        );
        SetConfigParam[] memory executorParams = new SetConfigParam[](1);
        executorParams[0] = SetConfigParam({
            eid: SONIC_CHAIN_ID,  // destination chain
            configType: 1,
            config: executorConfig
        });
        endpoint.setConfig(
            MESSAGE_SENDER,
            SEND_LIB_ADDRESS,
            executorParams
        );
        // DVN configuration only
        address[] memory dvnAddresses = new address[](0);
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DEFAULT_DVN;

        bytes memory dvnConfig = abi.encode((
            UlnConfig({
                confirmations: uint64(10),      // uint64 not uint8
                requiredDVNCount: uint8(1),
                optionalDVNCount: uint8(0),
                optionalDVNThreshold: uint8(0),
                requiredDVNs: requiredDVNs,    // empty array for required DVNs
                optionalDVNs: dvnAddresses     // array with DEFAULT_DVN
            })
        ));

        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam({
            eid: SONIC_CHAIN_ID,
            configType: 2,    // DVN config
            config: dvnConfig
        });

        endpoint.setConfig(
            MESSAGE_SENDER,
            SEND_LIB_ADDRESS,
            params
        );
        // transfer ownership of the relayer to MSIG after config is done
        ShadowMessageSender(MESSAGE_SENDER).transferOwnership(MSIG);
        console2.log("Relayer ownership transferred to MSIG");
        console2.log("LayerZero configurations set successfully");
        vm.stopBroadcast();
    }
} 