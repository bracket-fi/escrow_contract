//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EscrowBase} from "./EscrowBase.sol";

import {IL1GatewayRouter} from "token-bridge-contracts/tokenbridge/ethereum/gateway/IL1GatewayRouter.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Bracket's Escrow Contract
/// @author Bracket.fi
/// @dev L1 Escrow with capabilities for bridging the tokens to Arbitrum at the end of escrow.
contract BridgeEscrow is EscrowBase {
    using SafeERC20 for IERC20;

    IL1GatewayRouter public bridgeRouter;

    constructor() {
        _disableInitializers();
    }

    function initialize(address[] calldata tokens, address[] calldata rebase, uint256 breakTime, address router)
        external
        initializer
    {
        _EscrowBase_init(tokens, rebase, breakTime);

        bridgeRouter = IL1GatewayRouter(router);
    }

    function bridgeTokenArb(address token, address arbEscrow, uint256 amount, uint256 maxGas, uint256 gasPrice)
        public
        onlyOwner
        onlyBroke
    {
        IERC20(token).safeIncreaseAllowance(address(bridgeRouter), amount);
        bridgeRouter.outboundTransferCustomRefund(token, msg.sender, arbEscrow, amount, maxGas, gasPrice, bytes(""));
    }

    function bridgeTokenConnext(address token, address arbEscrow, uint256 amount, uint256 maxGas, uint256 gasPrice)
        public
        onlyOwner
        onlyBroke
    {}
}
