// SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import {ArbitrumDeploymentScript} from "./ArbitrumDeployment.s.sol";
import {MainnetDeploymentScript} from "./MainnetDeployment.s.sol";

contract MainnetDeploymentScript is Script {
    function run() public returns (address) {
        ArbitrumDeploymentScript arbitrumDeployment = new ArbitrumDeploymentScript();
        MainnetDeploymentScript mainnetDeployment = new MainnetDeploymentScript();

        arbitrumDeployment.run();
        mainnetDeployment.run();
    }
}
