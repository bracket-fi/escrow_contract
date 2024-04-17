// SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "./Config.sol";

import {MainEscrow} from "src/MainEscrow.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ArbitrumDeploymentScript is Script {
    function run() public returns (address) {
        address[] memory initTokens = new address[](5);
        address[] memory initRebase = new address[](5);

        initTokens[0] = ARBITRUM_WETH;
        initRebase[0] = ETH_MOCK_ADDRESS;
        initTokens[1] = ARBITRUM_WSTETH;
        initRebase[1] = address(0);
        initTokens[2] = ARBITRUM_RETH;
        initRebase[2] = address(0);
        initTokens[3] = ARBITRUM_EZETH;
        initRebase[3] = address(0);
        initTokens[4] = ARBITRUM_WEETH;
        initRebase[4] = address(0);

        vm.createSelectFork(vm.envString("ARBITRUM_RPC"));
        vm.startBroadcast();

        MainEscrow mainEscrowImpl = new MainEscrow();
        ERC1967Proxy mainEscrowProxy = new ERC1967Proxy(
            address(mainEscrowImpl),
            abi.encodeWithSignature(
                "initialize(address[],address[],uint256)", initTokens, initRebase, block.timestamp + ESCROW_TIME
            )
        );

        vm.stopBroadcast();

        console2.log("Arbitrum Escrow: ", address(mainEscrowProxy));

        return address(mainEscrowProxy);
    }
}
