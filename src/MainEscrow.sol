//SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import "./EscrowBase.sol";

/// @title Bracket's Escrow Contract
/// @author Bracket Finance
contract MainEscrow is EscrowBase {
    using SafeERC20 for IERC20;

    constructor() {
        _disableInitializers();
    }

    function initialize(address[] calldata tokens, address[] calldata rebase, uint256 breakTime) external initializer {
        _EscrowBase_init(tokens, rebase, breakTime);
    }
}
