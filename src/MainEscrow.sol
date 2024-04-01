//SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "./EscrowBase.sol";

/// @title Bracket's Escrow Contract
/// @author Bracket Finance
contract MainEscrow is EscrowBase {
    using SafeERC20 for IERC20;

    /// @notice The merkle roots for distributing tokens / points
    /// @dev Token Address -> Root
    mapping(address => bytes32) merkleRoots;
    /// @notice The amounts claimed through the merkle
    /// @dev User Address -> Token Address -> Claimed Amount
    mapping(address => mapping(address => uint256)) claimedAmounts;

    constructor() {
        _disableInitializers();
    }

    function initialize(address[] calldata tokens, address[] calldata rebase, uint256 breakTime) external initializer {
        _EscrowBase_init(tokens, rebase, breakTime);
    }

    /// @notice Claim tokens / points received during escrow, computed off-chain.
    /// @dev This is computed off-chain and distributed according to a merkle tree
    /// @param token The address of the token to withdraw
    /// @param amount The amount to withdraw
    /// @param proof The merkle proof
    function claimTokens(address token, uint256 amount, bytes32[] memory proof) external {
        bytes32 root = merkleRoots[token];
        uint256 claimed = claimedAmounts[msg.sender][token];

        if (root == bytes32(0)) revert NoTokenDistribution();
        if (proof.length == 0) revert InvalidMerkleProof();
        if (claimed >= amount) revert TokensAlreadyClaimed();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
        if (!MerkleProof.verify(proof, root, leaf)) revert InvalidMerkleProof();

        uint256 claimable = amount - claimed;
        claimedAmounts[msg.sender][token] = claimed + claimable;

        IERC20(token).safeTransfer(msg.sender, claimable);
    }

    /// @notice Change or add a merkle root for a given token
    /// @param token The address of the token to add
    /// @param root The merkle root of the tree
    function addMerkleRoot(address token, bytes32 root) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();

        merkleRoots[token] = root;
    }

    function withdrawEscrow(address[] calldata tokens) external onlyOwner onlyBroke {
        uint256 length = tokens.length;

        for (uint256 i; i < length; ++i) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance != 0) {
                token.safeTransfer(msg.sender, token.balanceOf(address(this)));
            }
        }
    }

    function getMerkleRoot(address token) external view returns (bytes32) {
        return merkleRoots[token];
    }

    function getClaimedAmount(address user, address token) external view returns (uint256) {
        return claimedAmounts[user][token];
    }
}
