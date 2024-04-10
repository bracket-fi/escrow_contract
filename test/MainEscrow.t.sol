// SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "./TestsBase.sol";

contract MainEscrowTests is TestsBase {
    function setUp() public override {
        super.setUp();
        vm.selectFork(forks[ForkChain.ARBITRUM]);
    }

    function test_depositTokens() public {
        uint256 tokenLength = tokens[ForkChain.ARBITRUM].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[ForkChain.ARBITRUM][i].token);

            assertEq(token.balanceOf(address(arbEscrow)), 100 ether, "Escrow pre-balance");

            deal(address(token), address(this), 100 ether);

            token.approve(address(arbEscrow), 100 ether);
            arbEscrow.depositToken(address(token), 100 ether);

            assertEq(token.balanceOf(address(arbEscrow)), 100 ether, "Escrow post-balance");
        }
    }

    function test_depositToken_notAddedToken() public {
        IERC20 token = IERC20(_deployMockToken());

        deal(address(token), address(this), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow pre-balance");

        token.approve(address(arbEscrow), 100 ether);
        vm.expectRevert();
        arbEscrow.depositToken(address(token), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow post-balance");
    }

    function test_depositToken_blacklisted() public {
        uint256 tokenLength = tokens[ForkChain.ARBITRUM].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[ForkChain.ARBITRUM][i].token);

            deal(address(token), address(this), 100 ether);

            assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow pre-balance");

            arbEscrow.whitelistToken(address(token), false);

            token.approve(address(arbEscrow), 100 ether);
            vm.expectRevert();
            arbEscrow.depositToken(address(token), 100 ether);

            assertEq(token.balanceOf(address(arbEscrow)), 0 ether, "Escrow post-balance");
        }
    }

    // function test_depositToken_brokeEscrow() public {
    //     IERC20 token = IERC20(tokens[0]);

    //     deal(address(token), address(this), 100 ether);

    //     assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow pre-balance");

    //     token.approve(address(arbEscrow), 100 ether);

    //     skip(30 days);

    //     vm.expectRevert();
    //     arbEscrow.depositToken(address(token), 100 ether);

    //     assertEq(token.balanceOf(address(arbEscrow)), 0 ether, "Escrow post-balance");
    // }
}
