// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @dev Interface of the BrktETH escrow contract.
interface IEscrow {
    error AlreadyBlacklisted();
    error AlreadyWhitelisted();
    error CallerIsNotBroker(address broker);
    error EscrowBroke();
    error EscrowNotBroke();
    error NotEnoughAmountStaked(uint256 amount);
    error NotWhitelisted(address token);
    error TVLUnderpaid(uint256 tvl);
    error ZeroAddress();
    error ZeroAmount();
    error NoTokenDistribution();
    error InvalidMerkleProof();
    error TokensAlreadyClaimed();
    error ArrayLengthMismatch();
    error TokenAlreadyAdded();
    error TokenCannotBeUnwrapped();
    error BreakTimeMustBeInTheFuture();
    error TokenNotAdded();
    error NoChanges();
    error WrapCallFailed();
    error CannotDepositETHAsToken();
    error ETHSendFailed();

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount, bool unwrapped);
}
