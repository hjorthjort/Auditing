// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {XShadow} from "../../../../contracts/xShadow/XShadow.sol";
import {Voter} from "../../../../contracts/Voter.sol";
import {xShadowInstance} from "../instances/xShadowTokenInstance.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library xShadowDeployLibrary {
    function deploy(
        address shadow,
        address voter,
        address operator,
        address accessHub,
        address voteModule,
        address minter
    ) internal returns (xShadowInstance memory) {
        XShadow xShadow = new XShadow(shadow, voter, operator, accessHub, voteModule, minter);

        require(xShadow.SHADOW() == IERC20(shadow), "Shadow mismatch");
        require(xShadow.VOTER() == Voter(voter), "Voter mismatch");
        require(xShadow.MINTER() == minter, "Minter mismatch");
        require(xShadow.ACCESS_HUB() == accessHub, "AccessHub mismatch");
        require(xShadow.VOTE_MODULE() == voteModule, "VoteModule mismatch");
        require(xShadow.operator() == operator, "Operator mismatch");

        return xShadowInstance({
            shadow: shadow,
            voter: voter,
            operator: operator,
            accessHub: accessHub,
            xShadow: address(xShadow),
            minter: minter
        });
    }
}
