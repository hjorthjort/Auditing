// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {ShadowMessageRecipient} from "contracts/migration/ShadowMessageRecipient.sol";
import {console2} from "forge-std/console2.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

contract ConfigureReceiver is Script {
    // V2 Endpoint address for Sonic
    address constant LZ_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant EXECUTOR_ADDRESS = 0x4208D6E27538189bB48E603D6123A94b8Abe0A0b;
    
    // V2 library addresses for Sonic
    address constant RECEIVE_LIB_ADDRESS = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    // Default DVN address
    address constant DEFAULT_DVN = 0x282b3386571f7f794450d5789911a9804FA346b4;
    // chain EIDs
    uint32 constant FANTOM_CHAIN_ID = 30112;
    uint32 constant SONIC_CHAIN_ID = 30332;
    // deployed contracts by us prior to this script
    address constant MSIG = 0xCAfc58De1E6A071790eFbB6B83b35397023E1544;
    address constant MESSAGE_SENDER = 0xf047f81EB5D76dcde0C292d783E161f26e885cE8; 
    address constant MESSAGE_RECEIVER = 0x8Cceb02D14F605850A2aaD9EB705092717047E04;

    ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // delegate to ourself (deployer)
        ShadowMessageRecipient(MESSAGE_RECEIVER).setDelegate(vm.addr(deployerPrivateKey));
        // update setPeer to include the peer address (using source chain ID)
        ShadowMessageRecipient(MESSAGE_RECEIVER).setPeer(FANTOM_CHAIN_ID, bytes32(uint256(uint160(MESSAGE_SENDER))));
        // configure LayerZero settings
        // set the receive library only
        endpoint.setReceiveLibrary(
            MESSAGE_RECEIVER,
            FANTOM_CHAIN_ID,
            RECEIVE_LIB_ADDRESS,
            0  // grace period
        );

        // DVN configuration
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
            eid: FANTOM_CHAIN_ID,
            configType: 2,    // DVN config
            config: dvnConfig
        });

        endpoint.setConfig(
            MESSAGE_RECEIVER,
            RECEIVE_LIB_ADDRESS,
            params
        );

        // transfer ownership of the receiver to MSIG after config is done
        ShadowMessageRecipient(MESSAGE_RECEIVER).transferOwnership(MSIG);
        console2.log("Receiver ownership transferred to MSIG");
        console2.log("LayerZero configurations set successfully");
        vm.stopBroadcast();
    }
} 