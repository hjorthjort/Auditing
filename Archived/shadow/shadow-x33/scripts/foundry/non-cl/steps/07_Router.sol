// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Router} from "../../../../contracts/Router.sol";
import {RouterInstance} from "../instances/RouterInstance.sol";

library DeployRouterLibrary {
    function deploy(address factory, address weth) internal returns (RouterInstance memory) {
        Router router = new Router(factory, weth);

        require(address(router.factory()) == factory, "Factory mismatch");
        require(address(router.WETH()) == weth, "WETH mismatch");

        return RouterInstance({router: address(router), factory: factory, weth: weth});
    }
}
