// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {UniswapInterfaceMulticall} from "contracts/CL/periphery/lens/UniswapInterfaceMulticall.sol";
import {UniswapInterfaceMulticallInstance} from "../instances/UniswapInterfaceMulticallInstance.sol";

library UniswapInterfaceMulticallLibrary {
    function deploy() internal returns (UniswapInterfaceMulticallInstance memory) {
        UniswapInterfaceMulticall uniswapInterfaceMulticall = new UniswapInterfaceMulticall();
        return UniswapInterfaceMulticallInstance({uniswapInterfaceMulticall: address(uniswapInterfaceMulticall)});
    }
}
