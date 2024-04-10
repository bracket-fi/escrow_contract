//SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "./Config.sol";

import {MainEscrow} from "src/MainEscrow.sol";
import {BridgeEscrow} from "src/BridgeEscrow.sol";

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract TestsBase is Test {
    enum ForkChain {
        MAINNET,
        ARBITRUM
    }

    struct Token {
        string name;
        address token;
        address rebase;
    }

    MainEscrow public arbEscrow;
    BridgeEscrow public ethEscrow;

    // Chain -> Fork ID
    mapping(ForkChain => uint256) internal forks;

    // Chain -> Tokens
    mapping(ForkChain => Token[]) internal tokens;

    function setUp() public virtual {
        _setupArbitrum();
        _setupMainnet();
    }

    function _setupArbitrum() internal {
        forks[ForkChain.ARBITRUM] = vm.createSelectFork(vm.envString("ARBITRUM_RPC"));

        tokens[ForkChain.ARBITRUM].push(Token({name: "WETH", token: ARBITRUM_WETH, rebase: ETH_MOCK_ADDRESS}));
        tokens[ForkChain.ARBITRUM].push(Token({name: "stETH", token: ARBITRUM_WSTETH, rebase: address(0)}));
        tokens[ForkChain.ARBITRUM].push(Token({name: "rETH", token: ARBITRUM_RETH, rebase: address(0)}));
        tokens[ForkChain.ARBITRUM].push(Token({name: "ezETH", token: ARBITRUM_EZETH, rebase: address(0)}));
        tokens[ForkChain.ARBITRUM].push(Token({name: "eETH", token: ARBITRUM_WEETH, rebase: address(0)}));

        uint256 length = tokens[ForkChain.ARBITRUM].length;

        address[] memory initTokens = new address[](length);
        address[] memory initRebase = new address[](length);

        for (uint256 i; i < length; ++i) {
            Token memory token = tokens[ForkChain.ARBITRUM][i];

            initTokens[i] = token.token;
            initRebase[i] = token.rebase;
        }

        uint256 breakTimestamp = block.timestamp + ESCROW_TIME;

        MainEscrow mainEscrowImpl = new MainEscrow();
        ERC1967Proxy mainEscrowProxy = new ERC1967Proxy(
            address(mainEscrowImpl),
            abi.encodeWithSignature("initialize(address[],address[],uint256)", initTokens, initRebase, breakTimestamp)
        );

        arbEscrow = MainEscrow(address(mainEscrowProxy));
    }

    function _setupMainnet() internal {
        forks[ForkChain.MAINNET] = vm.createSelectFork(vm.envString("MAINNET_RPC"));

        tokens[ForkChain.MAINNET].push(Token({name: "WETH", token: MAINNET_WETH, rebase: ETH_MOCK_ADDRESS}));
        tokens[ForkChain.MAINNET].push(Token({name: "stETH", token: MAINNET_WSTETH, rebase: MAINNET_STETH}));
        tokens[ForkChain.MAINNET].push(Token({name: "rETH", token: MAINNET_RETH, rebase: address(0)}));
        tokens[ForkChain.MAINNET].push(Token({name: "ezETH", token: MAINNET_EZETH, rebase: address(0)}));
        tokens[ForkChain.MAINNET].push(Token({name: "eETH", token: MAINNET_WEETH, rebase: MAINNET_EETH}));

        uint256 length = tokens[ForkChain.MAINNET].length;

        address[] memory initTokens = new address[](length);
        address[] memory initRebase = new address[](length);

        for (uint256 i; i < length; ++i) {
            Token memory token = tokens[ForkChain.MAINNET][i];

            initTokens[i] = token.token;
            initRebase[i] = token.rebase;
        }

        uint256 breakTimestamp = block.timestamp + ESCROW_TIME;

        BridgeEscrow bridgeEscrowImpl = new BridgeEscrow();
        ERC1967Proxy bridgeEscrowProxy = new ERC1967Proxy(
            address(bridgeEscrowImpl),
            abi.encodeWithSignature(
                "initialize(address[],address[],uint256,address)",
                initTokens,
                initRebase,
                breakTimestamp,
                MAINNET_BRIDGE
            )
        );

        ethEscrow = BridgeEscrow(address(bridgeEscrowProxy));
    }

    function _deployMockToken() internal returns (address) {
        return address(new ERC20Mock());
    }
}
