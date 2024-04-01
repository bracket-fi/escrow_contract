//SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "./TestsBase.sol";

contract MainEscrowTests is TestsBase {
    function test_depositToken() public {
        IERC20 token = IERC20(tokens[0]);

        deal(address(token), address(this), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow pre-balance");

        token.approve(address(arbEscrow), 100 ether);
        arbEscrow.depositToken(address(token), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 100 ether, "Escrow post-balance");
    }

    function test_depositToken_notAdded() public {
        IERC20 token = IERC20(_deployMockToken());

        deal(address(token), address(this), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow pre-balance");

        token.approve(address(arbEscrow), 100 ether);
        vm.expectRevert();
        arbEscrow.depositToken(address(token), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0 ether, "Escrow post-balance");
    }

    function test_depositToken_blacklisted() public {
        IERC20 token = IERC20(tokens[0]);

        deal(address(token), address(this), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow pre-balance");

        arbEscrow.whitelistToken(address(token), false);

        token.approve(address(arbEscrow), 100 ether);
        vm.expectRevert();
        arbEscrow.depositToken(address(token), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0 ether, "Escrow post-balance");
    }

    function test_depositToken_brokeEscrow() public {
        IERC20 token = IERC20(tokens[0]);

        deal(address(token), address(this), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0, "Escrow pre-balance");

        token.approve(address(arbEscrow), 100 ether);

        skip(30 days);

        vm.expectRevert();
        arbEscrow.depositToken(address(token), 100 ether);

        assertEq(token.balanceOf(address(arbEscrow)), 0 ether, "Escrow post-balance");
    }
}
