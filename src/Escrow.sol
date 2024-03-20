// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

import {IEscrow} from "./interfaces/IEscrow.sol";
import {RebaseWrapper} from "./RebaseWrapper.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Bracket's Escrow Contract
/// @author Bracket.fi
/// @dev
contract BracketEscrow is Initializable, Ownable2StepUpgradeable, UUPSUpgradeable, IEscrow {
// using SafeERC20 for IERC20;

// struct Token {
//     bool whitelisted;
//     bool rebase;
//     uint8 index;
//     uint240 totalStaked;
// }

// /// @notice Merkle root for each token distribution
// /// @dev Token Address -> Merkle Root
// mapping(address => bytes32) merkleRoots;

// /// @notice Claimed amount per user and per token distribution
// /// @dev User Address -> Token Address -> User Balance
// mapping(address => mapping(address => uint256)) claimedAmounts;

// /// @notice Supported Tokens Information
// /// @dev Token Address -> Token Information
// mapping(address => Token) tokens;

// /// @notice User tokens balances
// /// @dev User Address -> Token Address -> User Balance
// mapping(address => mapping(address => uint256)) usersBalance;

// /// @notice Wrapper contract for all the supported rebase tokens
// RebaseWrapper public wrapper;

// /// @notice The address of the broker that will be swapping the TVL for ETH.
// address public broker;

// /// @notice The value the broker must pay in ETH in exchange for the Escrow TVL.
// uint256 public tvlETH;

// /// @notice The timestamp at which the escrow will be broken
// uint256 public breakTime;

// modifier onlyNotBroke() {
//     if (_checkEscrowBreak()) revert EscrowBroke();
//     _;
// }

// modifier onlyBroke() {
//     if (!_checkEscrowBreak()) revert EscrowNotBroke();
//     _;
// }

// constructor() {
//     _disableInitializers();
// }

// function initialize(Token[] calldata tokens_, uint256 breakTime_) external initializer {
//     __Ownable2Step_init();

//     breakTime = breakTime_;
//     tokens = tokens_;
// }

// /// @notice Deposit tokens into the escrow
// /// @dev For rebase tokens the tokens will be wrapped on their non-rebase version, therefore the input amount may differ from the returned amount.
// /// @param token The address of the token to deposit
// /// @param amount The amount to deposit
// /// @return Deposited non-rebase tokens amount
// function deposit(address token, uint256 amount) external onlyNotBroke returns (uint256 depositedAmount) {
//     Token memory tokenInfo = tokens[token];
//     if (!tokenInfo.whitelisted) revert NotWhitelisted(token);
//     if (amount == 0) revert ZeroAmount();

//     IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

//     if (tokenInfo.rebase) {
//         amount = RebaseWrapper.wrap(token, amount);
//     }

//     usersBalance[msg.sender][token] += amount;
//     tokens[token].totalStaked += amount;

//     emit Deposit(msg.sender, token, amount);
// }

// /// @notice Withdraw tokens from the escrow
// /// @dev For rebase tokens the tokens will be unwrapped from their non-rebase version, therefore the input amount may differ from the returned amount.
// /// @param token The address of the token to withdraw
// /// @param amount The amount to withdraw
// /// @return Wihtdrawn amount
// function withdraw(address token, uint256 amount) external onlyNotBroke returns (uint256 amount) {
//     if (amount == 0) revert ZeroAmount();

//     uint256 balance = usersBalance[msg.sender][token];
//     if (amount > balance) revert NotEnoughAmountStaked(balance);

//     unchecked {
//         usersBalance[msg.sender][token] = balance - amount;
//         tokens[token].totalStaked -= amount;
//     }

//     IERC20(token).safeTransfer(msg.sender, amount);

//     emit Withdraw(msg.sender, token, amount);
// }

// function claimTokens(address token, uint256 amount, bytes32[] memory proof) external {
//     bytes32 root = merkleRoots[token];
//     uint256 claimed = claimedAmounts[msg.sender][token];

//     if (root == bytes32(0)) revert NoTokenDistribution();
//     if (proof.length == 0) revert InvalidMerkleProof();
//     if (claimed >= amount) revert TokensAlreadyClaimed();

//     bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
//     if (!MerkleProof.verify(proof, root, leaf)) revert InvalidMerkleProof();

//     uint256 claimable = amount - claimed;
//     claimedAmounts[msg.sender][token] = claimed + claimable;

//     IERC20(token).safeTransfer(msg.sender, claimable);
// }

// function setTvlETH(uint256 amount) external onlyOwner onlyBroke {
//     tvlETH = amount;
// }

// function payTvl(address[] tokens_) external payable onlyBroke {
//     if (msg.sender != broker) revert CallerIsNotBroker(broker);
//     if (msg.value < tvlETH) revert TVLUnderpaid(tvlETH);

//     uint256 length = tokens_.length;
//     for (uint256 i; i < length;) {
//         IERC20 token = IERC20(tokens_[i]);
//         token.safeTransfer(msg.sender, token.balanceOf(address(this)));

//         unchecked {
//             ++i;
//         }
//     }
// }

// function whitelistToken(address token, bool whitelisted) external onlyOwner {
//     if (token == address(0)) revert ZeroAddress();

//     Token memory oldTokenInfo = tokens[token];

//     if (tokenInfo.rebase != oldTokenInfo.rebase) revert RebaseCannotBeChanged();

//     tokens[token].whitelisted = whitelisted;
// }

// function _checkWhitelisted(address[] memory tokens_) internal view {
//     uint256 length = tokens_.length;

//     for (uint256 i; i < length;) {
//         _checkWhitelisted(tokens_[i]);

//         unchecked {
//             ++i;
//         }
//     }
// }

// function _checkEscrowBreak() internal view returns (bool) {
//     return (block.timestamp >= breakTime);
// }

// function _authorizeUpgrade(address) internal override onlyOwner {}
}
