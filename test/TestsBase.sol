//SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "./Config.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MainEscrow} from "src/MainEscrow.sol";

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract TestsBase is Test {
    MainEscrow public arbEscrow;

    address[] internal tokens;
    address[] internal rebase;

    function setUp() public {
        tokens.push(_deployMockToken());
        rebase.push(address(0));
        uint256 breakTimestamp = block.timestamp + ESCROW_TIME;

        MainEscrow mainEscrowImpl = new MainEscrow();
        ERC1967Proxy mainEscrowProxy = new ERC1967Proxy(
            address(mainEscrowImpl),
            abi.encodeWithSignature("initialize(address[],address[],uint256)", tokens, rebase, breakTimestamp)
        );

        arbEscrow = MainEscrow(address(mainEscrowProxy));
    }

    function _deployMockToken() internal returns (address) {
        return address(new ERC20Mock());
    }
}
