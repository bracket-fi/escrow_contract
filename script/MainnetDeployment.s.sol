// SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "./Config.sol";

import {BridgeEscrow} from "src/BridgeEscrow.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MainnetDeploymentScript is Script {
    function run() public returns (address) {
        address[] memory initTokens = new address[](5);
        address[] memory initRebase = new address[](5);

        initTokens[0] = ARBITRUM_WETH;
        initRebase[0] = ETH_MOCK_ADDRESS;
        initTokens[1] = MAINNET_WSTETH;
        initRebase[1] = MAINNET_STETH;
        initTokens[2] = MAINNET_RETH;
        initRebase[2] = address(0);
        initTokens[3] = MAINNET_EZETH;
        initRebase[3] = address(0);
        initTokens[4] = MAINNET_WEETH;
        initRebase[4] = MAINNET_EETH;

        vm.createSelectFork(vm.envString("MAINNET_RPC"));
        vm.startBroadcast();

        BridgeEscrow bridgeEscrowImpl = new BridgeEscrow();
        ERC1967Proxy bridgeEscrowProxy = new ERC1967Proxy(
            address(bridgeEscrowImpl),
            abi.encodeWithSignature(
                "initialize(address[],address[],uint256,address)",
                initTokens,
                initRebase,
                block.timestamp + ESCROW_TIME,
                MAINNET_BRIDGE
            )
        );

        vm.stopBroadcast();

        console2.log("Mainnet Escrow: ", address(bridgeEscrowProxy));

        return address(bridgeEscrowProxy);
    }
}
