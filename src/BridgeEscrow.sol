//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EscrowBase} from "./EscrowBase.sol";

/// @title Bracket's Escrow Contract
/// @author Bracket.fi
/// @dev L1 Escrow with capabilities for bridging the tokens to Arbitrum at the end of escrow.
contract BridgeEscrow is EscrowBase {}
