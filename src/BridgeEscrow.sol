//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EscrowBase} from "./EscrowBase.sol";

import {IL1GatewayRouter} from "token-bridge-contracts/tokenbridge/ethereum/gateway/IL1GatewayRouter.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IXERC20} from "xERC20/solidity/interfaces/IXERC20.sol";
import {XERC20Lockbox} from "xERC20/solidity/contracts/XERC20Lockbox.sol";
import {IConnext} from "connext/IConnext.sol";

/// @title Bracket's Escrow Contract
/// @author Bracket.fi
/// @dev L1 Escrow with capabilities for bridging the tokens to Arbitrum at the end of escrow.
contract BridgeEscrow is EscrowBase {
    using SafeERC20 for IERC20;

    IL1GatewayRouter public bridgeRouter;
    XERC20Lockbox public renzoLockbox;
    IConnext public connext;

    // Indicator for the fallback function to fail or not in order to test ETH unwrap.
    bool public failReceive;

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
        external
        onlyOwner
        onlyBroke
    {
        IERC20(token).safeIncreaseAllowance(address(bridgeRouter), amount);
        bridgeRouter.outboundTransferCustomRefund(token, msg.sender, arbEscrow, amount, maxGas, gasPrice, bytes(""));
    }

    function bridgeTokenConnext(address token, address arbEscrow, uint256 amount, uint256 slippage, uint256 relayerFee)
        external
        onlyOwner
        onlyBroke
    {
        IERC20(token).safeIncreaseAllowance(address(renzoLockbox), amount);

        IXERC20 xToken = renzoLockbox.XERC20();
        renzoLockbox.deposit(amount);

        IERC20(address(xToken)).safeIncreaseAllowance(address(renzoLockbox), amount);
        connext.xcall{value: relayerFee}(
            1634886255, // _destination: Domain ID of the destination chain
            arbEscrow, // _to: address receiving the funds on the destination
            address(xToken), // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            amount, // _amount: amount of tokens to transfer
            slippage, // _slippage: the maximum amount of slippage the user will accept in BPS (e.g. 30 = 0.3%)
            bytes("") // _callData: empty bytes because we're only sending funds
        );
    }
}
