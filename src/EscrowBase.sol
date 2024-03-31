//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

import {IEscrow} from "./interfaces/IEscrow.sol";
import {RebaseWrapper} from "./RebaseWrapper.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Bracket's Escrow Base Contract
/// @author Bracket Finance
/// @dev Has the basic functionality shared across the different escrows and it is the contract from which the other contracts inherit from
abstract contract EscrowBase is Initializable, Ownable2StepUpgradeable, UUPSUpgradeable, IEscrow {
    using SafeERC20 for IERC20;

    struct Token {
        bool whitelisted;
        bool rebase;
        uint248 totalStaked;
    }

    struct EscrowBaseStorage {
        /// @notice Supported Tokens Information
        /// @dev Token Address -> Token Information
        mapping(address => Token) tokens;
        /// @notice Users tokens balance
        /// @dev User Address -> Token Address -> User Balance
        mapping(address => mapping(address => uint256)) usersBalance;
        /// @notice The merkle roots for distributing tokens / points
        /// @dev Token Address -> Root
        mapping(address => bytes32) merkleRoots;
        /// @notice The amounts claimed through the merkle
        /// @dev User Address -> Token Address -> Claimed Amount
        mapping(address => mapping(address => uint256)) claimedAmounts;
        /// @notice Wrapper contract for all the supported rebase tokens
        RebaseWrapper wrapper;
        /// @notice The timestamp at which the escrow will be broken
        uint96 breakTimestamp;
    }

    //keccak256(abi.encode(uint256(keccak256("bracket.storage.EscrowBase")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant EscrowBaseStorageLocation =
        0x9dfdb17072058f593e63457bc4139b3bfabeded6460e926b6605e5f3a1dc4700;

    modifier onlyNotBroke() {
        if (_checkEscrowBreak()) revert EscrowBroke();
        _;
    }

    modifier onlyBroke() {
        if (!_checkEscrowBreak()) revert EscrowNotBroke();
        _;
    }

    function _EscrowBase_init(address[] calldata tokens, bool[] calldata rebase, uint256 breakTime)
        internal
        onlyInitializing
    {
        __Ownable2Step_init();

        if (breakTime <= block.timestamp) revert BreakTimeMustBeInTheFuture();

        uint256 length = tokens.length;
        if (length != rebase.length) revert ArrayLengthMismatch();

        for (uint256 i; i < length;) {
            addToken(tokens[i], rebase[i]);

            unchecked {
                ++i;
            }
        }

        breakTime = breakTime;
    }

    /// @notice Deposit tokens into the escrow
    /// @dev For rebase tokens the tokens will be wrapped on their non-rebase version, therefore the input amount may differ from the returned amount.
    /// @param token The address of the token to deposit
    /// @param amount The amount to deposit
    /// @return Deposited non-rebase tokens amount
    function deposit(address token, uint256 amount) external onlyNotBroke returns (uint256) {
        if (amount == 0) revert ZeroAmount();

        EscrowBaseStorage storage s = _getStorage();
        Token memory tokenInfo = s.tokens[token];

        if (!tokenInfo.whitelisted) revert NotWhitelisted(token);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (tokenInfo.rebase) {
            amount = s.wrapper.wrap(token, amount);
        }

        s.usersBalance[msg.sender][token] += amount;
        s.tokens[token].totalStaked += uint248(amount);

        emit Deposit(msg.sender, token, amount);

        return amount;
    }

    /// @notice Withdraw tokens from the escrow
    /// @param token The address of the token to withdraw
    /// @param amount The amount to withdraw
    function withdraw(address token, uint256 amount) external onlyNotBroke {
        if (amount == 0) revert ZeroAmount();

        EscrowBaseStorage storage s = _getStorage();

        uint256 balance = s.usersBalance[msg.sender][token];
        if (amount > balance) revert NotEnoughAmountStaked(balance);

        unchecked {
            s.usersBalance[msg.sender][token] = balance - amount;
            s.tokens[token].totalStaked -= uint248(amount);
        }

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, token, amount);
    }

    /// @notice Claim tokens / points received during escrow, computed off-chain.
    /// @dev This is computed off-chain and distributed according to a merkle tree.
    /// @param token The address of the token to withdraw
    /// @param amount The amount to withdraw
    /// @param proof The merkle proof
    function claimTokens(address token, uint256 amount, bytes32[] memory proof) external {
        EscrowBaseStorage storage s = _getStorage();

        bytes32 root = s.merkleRoots[token];
        uint256 claimed = s.claimedAmounts[msg.sender][token];

        if (root == bytes32(0)) revert NoTokenDistribution();
        if (proof.length == 0) revert InvalidMerkleProof();
        if (claimed >= amount) revert TokensAlreadyClaimed();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
        if (!MerkleProof.verify(proof, root, leaf)) revert InvalidMerkleProof();

        uint256 claimable = amount - claimed;
        s.claimedAmounts[msg.sender][token] = claimed + claimable;

        IERC20(token).safeTransfer(msg.sender, claimable);
    }

    function getTokenInfo(address token) external view returns (Token memory) {
        EscrowBaseStorage storage s = _getStorage();

        return s.tokens[token];
    }

    function getUserBalance(address user, address token) external view returns (uint256) {
        EscrowBaseStorage storage s = _getStorage();

        return s.usersBalance[user][token];
    }

    function getMerkleRoot(address token) external view returns (bytes32) {
        EscrowBaseStorage storage s = _getStorage();

        return s.merkleRoots[token];
    }

    function getClaimedAmount(address user, address token) external view returns (uint256) {
        EscrowBaseStorage storage s = _getStorage();

        return s.claimedAmounts[user][token];
    }

    function getWrapper() external view returns (address) {
        EscrowBaseStorage storage s = _getStorage();

        return address(s.wrapper);
    }

    function getBreakTimestamp() external view returns (uint96) {
        EscrowBaseStorage storage s = _getStorage();

        return s.breakTimestamp;
    }

    /// @notice Add token to the whitelist
    /// @param token The address of the token to add
    /// @param rebase Whether the token is a rebase token
    function addToken(address token, bool rebase) public onlyOwner {
        if (token == address(0)) revert ZeroAddress();

        EscrowBaseStorage storage s = _getStorage();

        if (s.tokens[token].whitelisted || s.tokens[token].totalStaked != 0) revert TokenAlreadyAdded();

        s.tokens[token].whitelisted = true;

        if (rebase) {
            s.tokens[token].rebase = true;
        }
    }

    /// @notice Change whitelist of a token
    /// @param token The address of the token to whitelist / blacklist
    /// @param whitelisted Whether to whitelist or blacklist
    function whitelistToken(address token, bool whitelisted) external onlyOwner {
        EscrowBaseStorage storage s = _getStorage();

        if (whitelisted && s.tokens[token].totalStaked == 0) revert TokenNotAdded();
        if (s.tokens[token].whitelisted == whitelisted) revert NoChanges();

        s.tokens[token].whitelisted = whitelisted;
    }

    /// @notice Change or add a merkle root for a given token
    /// @param token The address of the token to add
    /// @param root The merkle root of the tree
    function addMerkleRoot(address token, bytes32 root) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();

        EscrowBaseStorage storage s = _getStorage();

        s.merkleRoots[token] = root;
    }

    /// @notice Check whether the escrow is already broke
    function _checkEscrowBreak() internal view returns (bool) {
        EscrowBaseStorage storage s = _getStorage();

        return (block.timestamp >= s.breakTimestamp);
    }

    /// @notice Authorize upgrade only to the contract's owner (multisig)
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Get EscrowBase contract's storage
    function _getStorage() private pure returns (EscrowBaseStorage storage s) {
        assembly {
            s.slot := EscrowBaseStorageLocation
        }
    }
}
