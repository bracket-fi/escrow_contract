//SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import {EscrowBase} from "./EscrowBase.sol";

/// @title Bracket's Escrow Contract
/// @author Bracket Finance
/// @dev
contract MainEscrow is EscrowBase {
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] calldata tokens, bool[] calldata rebase, uint256 breakTime) external initializer {
        _EscrowBase_init(tokens, rebase, breakTime);
    }

    function 
}
