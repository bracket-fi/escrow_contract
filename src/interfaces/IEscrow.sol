// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @dev Interface of the BrktETH escrow contract.
interface IEscrow {
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount, bool unwrapped);

    error AlreadyBlacklisted();
    error AlreadyWhitelisted();
    error ArrayLengthMismatch();
    error BreakTimeMustBeInTheFuture();
    error CallerIsNotBroker(address broker);
    error CannotUseETHAddress();
    error ETHSendFailed();
    error EscrowBroke();
    error EscrowNotBroke();
    error InvalidMerkleProof();
    error NoChanges();
    error NoTokenDistribution();
    error NotEnoughAmountStaked(uint256 amount);
    error NotWhitelisted(address token);
    error TVLUnderpaid(uint256 tvl);
    error TokenAlreadyAdded();
    error TokenCannotBeUnwrapped();
    error TokenNotAdded();
    error TokensAlreadyClaimed();
    error WrapCallFailed();
    error ZeroAddress();
    error ZeroAmount();

    struct Token {
        bool whitelisted;
        address rebase;
        uint256 totalStaked;
    }

    /// @notice Deposit tokens into the escrow
    /// @dev For rebase tokens the tokens will be wrapped on their non-rebase version, therefore the input amount may differ from the returned amount.
    /// @param token The address of the token to deposit
    /// @param amount The amount to deposit
    /// @return Deposited non-rebase tokens amount
    function depositToken(address token, uint256 amount) external returns (uint256);

    /// @notice Deposit ETH into the escrow
    /// @dev ETH sent will be wrapped into WETH and deposited.
    function depositETH() external payable;

    /// @notice Withdraw tokens from the escrow
    /// @dev For rebase tokens the tokens will be unwrapped on their rebase version, therefore the input amount may differ from the transfered and returned amount.
    /// @param token The address of the token to withdraw
    /// @param amount The amount to withdraw
    /// @param unwrap Whether to unwrap the tokens or not
    /// @return Transfered rebase tokens amount
    function withdraw(address token, uint256 amount, bool unwrap) external returns (uint256);

    /// @notice Claim tokens / points received during escrow, computed off-chain.
    /// @dev This is computed off-chain and distributed according to a merkle tree.
    /// @param token The address of the token to withdraw
    /// @param amount The amount to withdraw
    /// @param proof The merkle proof
    function claimTokens(address token, uint256 amount, bytes32[] memory proof) external;

    /// @notice Change whitelist of a token
    /// @param token The address of the token to whitelist / blacklist
    /// @param whitelisted Whether to whitelist or blacklist
    function whitelistToken(address token, bool whitelisted) external;

    /// @notice Change or add a merkle root for a given token
    /// @param token The address of the token to add
    /// @param root The merkle root of the tree
    function addMerkleRoot(address token, bytes32 root) external;

    /// @notice Add token to the whitelist
    /// @param token The address of the token to add
    /// @param rebase The rebase version address if any
    function addToken(address token, address rebase) external;

    /// @notice Extend escrow break timestamp
    /// @param extendTime The amount of seconds to extend the timestamp with
    function extendEscrowBreak(uint256 extendTime) external;

    function getTokenInfo(address token) external view returns (Token memory);

    function getUserBalance(address user, address token) external view returns (uint256);

    function getMerkleRoot(address token) external view returns (bytes32);

    function getClaimedAmount(address user, address token) external view returns (uint256);

    function getBreakTimestamp() external view returns (uint256);
}
