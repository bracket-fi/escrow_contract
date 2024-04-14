// SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "./TestsBase.sol";

contract MainEscrowTests is TestsBase {
    function setUp() public override {
        super.setUp();
        vm.selectFork(forks[ForkChain.ARBITRUM]);

        activeFork = ForkChain.ARBITRUM;
        activeEscrow = IEscrow(address(arbEscrow));
    }

    // TODO: test token info getter.
    // TODO: test unwrap on bridge contract.
    // TODO: test bridge expect call.
}
