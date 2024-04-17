// SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "./TestsBase.sol";

import {Merkle} from "murky/Merkle.sol";

contract MainEscrowTests is TestsBase {
    address public USER_1 = makeAddr("USER 1");
    address public USER_2 = makeAddr("USER 2");
    address public USER_3 = makeAddr("USER 3");
    address public USER_4 = makeAddr("USER 4");

    bytes32 public root;

    bytes32[] public proof1;
    bytes32[] public proof2;
    bytes32[] public proof3;
    bytes32[] public proof4;

    function setUp() public override {
        super.setUp();
        vm.selectFork(forks[ForkChain.ARBITRUM]);

        activeFork = ForkChain.ARBITRUM;
        activeEscrow = IEscrow(address(arbEscrow));
    }

    function test_ClaimTokens() public {
        IERC20 mockToken = IERC20(_deployMockToken());

        _buildMockMerkle(0);

        arbEscrow.addMerkleRoot(address(mockToken), root);

        _assertMerkleClaim(address(mockToken), USER_1, 1 ether, 1 ether, proof1);
        _assertMerkleClaim(address(mockToken), USER_2, 20 ether, 20 ether, proof2);
        _assertMerkleClaim(address(mockToken), USER_3, 300 ether, 300 ether, proof3);
        _assertMerkleClaim(address(mockToken), USER_4, 4_000 ether, 4_000 ether, proof4);

        _buildMockMerkle(100 ether);

        arbEscrow.addMerkleRoot(address(mockToken), root);

        _assertMerkleClaim(address(mockToken), USER_1, 101 ether, 100 ether, proof1);
        _assertMerkleClaim(address(mockToken), USER_2, 120 ether, 100 ether, proof2);
        _assertMerkleClaim(address(mockToken), USER_3, 400 ether, 100 ether, proof3);
        _assertMerkleClaim(address(mockToken), USER_4, 4_100 ether, 100 ether, proof4);
    }

    function testFail_ClaimTokens_AboveAmount() public {
        IERC20 mockToken = IERC20(_deployMockToken());

        _buildMockMerkle(0);

        arbEscrow.addMerkleRoot(address(mockToken), root);

        _assertMerkleClaim(address(mockToken), USER_1, 2 ether, 2 ether, proof1);
        _assertMerkleClaim(address(mockToken), USER_2, 21 ether, 21 ether, proof2);
        _assertMerkleClaim(address(mockToken), USER_3, 301 ether, 301 ether, proof3);
        _assertMerkleClaim(address(mockToken), USER_4, 4_001 ether, 4_001 ether, proof4);
    }

    function _assertMerkleClaim(address token, address user, uint256 amount, uint256 claimable, bytes32[] memory proof)
        internal
    {
        deal(address(token), address(arbEscrow), claimable);

        uint256 userPreBal = IERC20(token).balanceOf(address(user));

        assertTrue(IERC20(token).balanceOf(address(arbEscrow)) >= claimable, "Pre-claim escrow token amount");

        vm.prank(user);
        arbEscrow.claimTokens(token, amount, proof);

        assertEq(IERC20(token).balanceOf(address(arbEscrow)), 0, "Post-claim escrow token amount");
        assertEq(IERC20(token).balanceOf(address(user)), userPreBal + claimable, "Post-claim user token amount");
    }

    function _buildMockMerkle(uint256 delta) internal {
        // Initialize
        Merkle m = new Merkle();

        // Mock Data
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(bytes.concat(keccak256(abi.encode(USER_1, 1 ether + delta))));
        data[1] = keccak256(bytes.concat(keccak256(abi.encode(USER_2, 20 ether + delta))));
        data[2] = keccak256(bytes.concat(keccak256(abi.encode(USER_3, 300 ether + delta))));
        data[3] = keccak256(bytes.concat(keccak256(abi.encode(USER_4, 4_000 ether + delta))));

        // Get Root, Proof, and Verify
        root = m.getRoot(data);

        proof1 = m.getProof(data, 0);
        proof2 = m.getProof(data, 1);
        proof3 = m.getProof(data, 2);
        proof4 = m.getProof(data, 3);
    }
}
