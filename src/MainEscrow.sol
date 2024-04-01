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

    function initialize(address[] calldata tokens, address[] calldata rebase, uint96 breakTime) external initializer {
        _EscrowBase_init(tokens, rebase, breakTime);
    }

    function withdrawEscrow(address[] calldata tokens) external onlyOwner onlyBroke {
        uint256 length = tokens.length;

        for (uint256 i; i < length; ++i) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }
}
