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
    error UnwrapCallFailed();
    error WrapCallFailed();
    error ZeroAddress();
    error ZeroAmount();
    error CannotSetEscrowBreakInThePast();

    struct Token {
        bool whitelisted;
        address rebase;
        uint256 totalStaked;
    }

    /// @notice Deposit tokens into the escrow
    /// @dev For rebase tokens the tokens will be wrapped on their non-rebase version, therefore the input amount may differ from the returned amount
    /// @param token The address of the token to deposit
    /// @param amount The amount to deposit
    /// @return Deposited non-rebase tokens amount
    function depositToken(address token, uint256 amount) external returns (uint256);

    /// @notice Deposit ETH into the escrow
    /// @dev ETH sent will be wrapped into WETH and deposited
    function depositETH() external payable;

    /// @notice Withdraw tokens from the escrow
    /// @dev For rebase tokens the tokens will be unwrapped on their rebase version, therefore the input amount may differ from the transfered and returned amount
    /// @param token The address of the token to withdraw
    /// @param amount The amount to withdraw
    /// @param unwrap Whether to unwrap the tokens or not
    /// @return Transfered rebase tokens amount
    function withdraw(address token, uint256 amount, bool unwrap) external returns (uint256);

    /// @notice Change whitelist of a token
    /// @param token The address of the token to whitelist / blacklist
    /// @param whitelisted Whether to whitelist or blacklist
    function whitelistToken(address token, bool whitelisted) external;

    /// @notice Add token to the whitelist
    /// @param token The address of the token to add
    /// @param rebase The rebase version address if any
    function addToken(address token, address rebase) external;

    /// @notice Set the escrow break timestamp
    /// @param breakTimestamp The timestamp of the new escrow break
    function setEscrowBreak(uint256 breakTimestamp) external;

    function getTokenInfo(address token) external view returns (Token memory);

    function getWrappedToken(address token) external view returns (address);

    function getUserBalance(address user, address token) external view returns (uint256);

    function getBreakTimestamp() external view returns (uint256);
}
