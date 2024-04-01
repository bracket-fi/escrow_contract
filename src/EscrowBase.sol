//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

import {IEscrow} from "./interfaces/IEscrow.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Bracket's Escrow Base Contract
/// @author Bracket Finance
/// @dev Has the basic functionality shared across the different escrows and it is the contract from which the other contracts inherit from
abstract contract EscrowBase is Initializable, Ownable2StepUpgradeable, UUPSUpgradeable, IEscrow {
    using SafeERC20 for IERC20;

    struct EscrowBaseStorage {
        /// @notice Supported Tokens Information
        /// @dev Token Address -> Token Informatio
        mapping(address => Token) tokens;
        /// @notice Wrapped Tokens Addresses
        /// @dev Rebase Token Address -> Wrapped Token Address
        mapping(address => address) wrappedTokens;
        /// @notice Users tokens balance
        /// @dev User Address -> Token Address -> User Balance
        mapping(address => mapping(address => uint256)) usersBalance;
        /// @notice The merkle roots for distributing tokens / points
        /// @dev Token Address -> Root
        mapping(address => bytes32) merkleRoots;
        /// @notice The amounts claimed through the merkle
        /// @dev User Address -> Token Address -> Claimed Amount
        mapping(address => mapping(address => uint256)) claimedAmounts;
        /// @notice The timestamp at which the escrow will be broken
        uint256 breakTimestamp;
    }

    //address(uint160(uint256(keccak256("bracket.eth.native.address"))));
    address private constant ETH_ADDRESS = 0x1F020C40136a8cdaF7b20821dA30e59D44f2e9Ae;

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

    function _EscrowBase_init(address[] calldata tokens, address[] calldata rebase, uint256 breakTimestamp)
        internal
        onlyInitializing
    {
        __Ownable2Step_init();
        _transferOwnership(msg.sender);

        if (breakTimestamp <= block.timestamp) revert BreakTimeMustBeInTheFuture();

        uint256 length = tokens.length;
        if (length != rebase.length) revert ArrayLengthMismatch();

        for (uint256 i; i < length;) {
            addToken(tokens[i], rebase[i]);

            unchecked {
                ++i;
            }
        }

        extendEscrowBreak(breakTimestamp);
    }

    function depositToken(address token, uint256 amount) external onlyNotBroke returns (uint256) {
        if (token == ETH_ADDRESS) revert CannotUseETHAddress();
        if (amount == 0) revert ZeroAmount();

        EscrowBaseStorage storage s = _getStorage();

        address wrapped = s.wrappedTokens[token];
        // If token needs to be wrapped
        if (wrapped != address(0)) {
            Token memory tokenInfo = s.tokens[wrapped];
            if (!tokenInfo.whitelisted) revert NotWhitelisted(wrapped);

            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            amount = _wrapStdLST(wrapped, amount);

            _deposit(wrapped, amount);
        } else {
            Token memory tokenInfo = s.tokens[token];
            if (!tokenInfo.whitelisted) revert NotWhitelisted(token);

            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            _deposit(token, amount);
        }

        return amount;
    }

    function depositETH() external payable onlyNotBroke {
        if (msg.value == 0) revert ZeroAmount();

        EscrowBaseStorage storage s = _getStorage();

        address wETH = s.wrappedTokens[ETH_ADDRESS];

        _wrapETH(wETH, msg.value);
        _deposit(wETH, msg.value);
    }

    function _deposit(address token, uint256 amount) private {
        EscrowBaseStorage storage s = _getStorage();

        s.usersBalance[msg.sender][token] += amount;
        s.tokens[token].totalStaked += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount, bool unwrap) external onlyNotBroke returns (uint256) {
        if (amount == 0) revert ZeroAmount();

        EscrowBaseStorage storage s = _getStorage();

        uint256 balance = s.usersBalance[msg.sender][token];
        if (amount > balance) revert NotEnoughAmountStaked(balance);

        uint256 finalAmt = amount;
        if (unwrap) {
            Token memory tokenInfo = s.tokens[token];
            if (tokenInfo.rebase == address(0)) {
                revert TokenCannotBeUnwrapped();
            } else if (tokenInfo.rebase == ETH_ADDRESS) {
                _unwrapETH(token, amount);
                (bool success,) = msg.sender.call{value: amount}("");
                if (!success) revert ETHSendFailed();
            } else {
                finalAmt = _unwrapStdLST(token, amount);
                IERC20(tokenInfo.rebase).safeTransfer(msg.sender, finalAmt);
            }
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }

        unchecked {
            s.usersBalance[msg.sender][token] = balance - amount;
            s.tokens[token].totalStaked -= amount;
        }

        emit Withdraw(msg.sender, token, amount, unwrap);

        return finalAmt;
    }

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

    function whitelistToken(address token, bool whitelisted) external onlyOwner {
        EscrowBaseStorage storage s = _getStorage();

        if (whitelisted && s.tokens[token].totalStaked == 0) revert TokenNotAdded();
        if (s.tokens[token].whitelisted == whitelisted) revert NoChanges();

        s.tokens[token].whitelisted = whitelisted;
    }

    function addMerkleRoot(address token, bytes32 root) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();

        EscrowBaseStorage storage s = _getStorage();

        s.merkleRoots[token] = root;
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

    function getBreakTimestamp() external view returns (uint256) {
        EscrowBaseStorage storage s = _getStorage();

        return s.breakTimestamp;
    }

    function addToken(address token, address rebase) public onlyOwner {
        if (token == address(0)) revert ZeroAddress();

        EscrowBaseStorage storage s = _getStorage();

        if (s.tokens[token].whitelisted || s.tokens[token].totalStaked != 0) revert TokenAlreadyAdded();

        s.tokens[token].whitelisted = true;

        if (rebase != address(0)) {
            s.tokens[token].rebase = rebase;
            s.wrappedTokens[rebase] = token;
        }
    }

    function extendEscrowBreak(uint256 extendTime) public onlyOwner {
        EscrowBaseStorage storage s = _getStorage();

        if (extendTime == 0) revert NoChanges();

        s.breakTimestamp += extendTime;
    }

    /// @notice Check whether the escrow is already broke
    function _checkEscrowBreak() internal view returns (bool) {
        EscrowBaseStorage storage s = _getStorage();

        return (block.timestamp >= s.breakTimestamp);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _wrapETH(address wETH, uint256 amount) private {
        (bool success,) = wETH.call{value: amount}(abi.encodeWithSignature("deposit()"));

        if (!success) revert WrapCallFailed();
    }

    function _wrapStdLST(address wrapped, uint256 amount) private returns (uint256) {
        (bool success, bytes memory returnData) = wrapped.call(abi.encodeWithSignature("wrap(uint256)", amount));
        if (!success) revert WrapCallFailed();

        return abi.decode(returnData, (uint256));
    }

    function _unwrapETH(address wETH, uint256 amount) private {
        (bool success,) = wETH.call(abi.encodeWithSignature("withdraw(uint256)", amount));

        if (!success) revert WrapCallFailed();
    }

    function _unwrapStdLST(address wrapped, uint256 amount) private returns (uint256) {
        (bool success, bytes memory returnData) = wrapped.call(abi.encodeWithSignature("unwrap(uint256)", amount));
        if (!success) revert WrapCallFailed();

        return abi.decode(returnData, (uint256));
    }

    /// @notice Get EscrowBase contract's storage
    function _getStorage() private pure returns (EscrowBaseStorage storage s) {
        assembly {
            s.slot := EscrowBaseStorageLocation
        }
    }
}
