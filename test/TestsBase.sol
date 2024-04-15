//SPDX-License-Identifier: UNLICENSED
// © Bracket Finance
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "script/Config.sol";

import {IEscrow} from "src/interfaces/IEscrow.sol";
import {MainEscrow} from "src/MainEscrow.sol";
import {BridgeEscrow} from "src/BridgeEscrow.sol";

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

abstract contract TestsBase is Test {
    enum ForkChain {
        MAINNET,
        ARBITRUM
    }

    struct Token {
        string name;
        address token;
        address rebase;
    }

    IEscrow public activeEscrow;
    MainEscrow public arbEscrow;
    BridgeEscrow public ethEscrow;

    ForkChain activeFork;

    // Chain -> Fork ID
    mapping(ForkChain => uint256) internal forks;

    // Chain -> Tokens
    mapping(ForkChain => Token[]) internal tokens;

    // Indicator for the fallback function to fail or not in order to test ETH unwrap.
    bool public failReceive;

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

        arbEscrow = MainEscrow(payable(address(mainEscrowProxy)));
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
                "initialize(address[],address[],uint256,address,address)",
                initTokens,
                initRebase,
                breakTimestamp,
                MAINNET_BRIDGE,
                CONNEXT_BRIDGE
            )
        );

        ethEscrow = BridgeEscrow(payable(address(bridgeEscrowProxy)));
    }

    function test_fuzz_depositToken(uint256 amount) public {
        amount = bound(amount, 1, 90_000 ether);

        uint256 tokenLength = tokens[activeFork].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[activeFork][i].token);

            assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow pre-deposit balance");
            assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow pre-balance");

            deal(address(token), address(this), amount);

            token.approve(address(activeEscrow), amount);
            activeEscrow.depositToken(address(token), amount);

            assertEq(token.balanceOf(address(activeEscrow)), amount, "Escrow post-balance");
            assertEq(
                activeEscrow.getUserBalance(address(this), address(token)), amount, "User escrow post-deposit balance"
            );
        }
    }

    function test_fuzz_depositToken_Wrap(uint256 amount) public {
        amount = bound(amount, 1, 90_000 ether);

        uint256 tokenLength = tokens[activeFork].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[activeFork][i].token);

            IEscrow.Token memory tokenInfo = activeEscrow.getTokenInfo(address(token));
            IERC20 rebaseToken = IERC20(tokenInfo.rebase);

            if (address(rebaseToken) == address(0) || address(rebaseToken) == ETH_MOCK_ADDRESS) {
                continue;
            }

            assertEq(rebaseToken.balanceOf(address(activeEscrow)), 0, "Escrow rebase token pre-balance");
            assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow pre-deposit balance");
            assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow pre-balance");

            deal(address(token), address(this), amount);
            token.approve(address(token), amount);

            (bool success, bytes memory returnData) =
                address(token).call(abi.encodeWithSignature("unwrap(uint256)", amount));
            require(success, "Unwrap call failed");

            uint256 unwrappedAmt = abi.decode(returnData, (uint256));

            rebaseToken.approve(address(activeEscrow), unwrappedAmt);
            uint256 returnedAmount = activeEscrow.depositToken(address(rebaseToken), unwrappedAmt);

            assertEq(rebaseToken.balanceOf(address(activeEscrow)), 0, "Escrow rebase token post-balance");
            assertEq(token.balanceOf(address(activeEscrow)), returnedAmount, "Escrow wrapped token post-balance");
            assertEq(
                activeEscrow.getUserBalance(address(this), address(token)),
                returnedAmount,
                "User escrow token post-deposit balance"
            );
        }
    }

    function test_depositToken_notAddedToken() public {
        IERC20 token = IERC20(_deployMockToken());

        deal(address(token), address(this), 100 ether);

        assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow pre-deposit balance");
        assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow pre-balance");

        token.approve(address(activeEscrow), 100 ether);
        vm.expectRevert();
        activeEscrow.depositToken(address(token), 100 ether);

        assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow post-balance");
        assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow post-deposit balance");
    }

    function test_depositToken_blacklisted() public {
        uint256 tokenLength = tokens[activeFork].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[activeFork][i].token);

            deal(address(token), address(this), 100 ether);

            assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow pre-deposit balance");
            assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow pre-balance");

            activeEscrow.whitelistToken(address(token), false);

            token.approve(address(activeEscrow), 100 ether);
            vm.expectRevert();
            activeEscrow.depositToken(address(token), 100 ether);

            assertEq(token.balanceOf(address(activeEscrow)), 0 ether, "Escrow post-balance");
            assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow post-balance");
        }
    }

    function test_depositToken_brokeEscrow() public {
        skip(ESCROW_TIME);

        uint256 tokenLength = tokens[activeFork].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[activeFork][i].token);

            deal(address(token), address(this), 100 ether);

            assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow pre-deposit balance");
            assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow pre-balance");

            token.approve(address(activeEscrow), 100 ether);

            vm.expectRevert();
            activeEscrow.depositToken(address(token), 100 ether);

            assertEq(token.balanceOf(address(activeEscrow)), 0 ether, "Escrow post-balance");
            assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow post-balance");
        }
    }

    function test_depositToken_ETH_MOCK() public {
        deployCodeTo("ERC20Mock.sol", ETH_MOCK_ADDRESS);

        IERC20 token = IERC20(address(ETH_MOCK_ADDRESS));
        IERC20 tokenWETH;
        if (vm.activeFork() == forks[ForkChain.MAINNET]) {
            tokenWETH = IERC20(MAINNET_WETH);
        } else if (vm.activeFork() == forks[ForkChain.ARBITRUM]) {
            tokenWETH = IERC20(ARBITRUM_WETH);
        } else {
            revert("Chain not supported");
        }

        assertEq(
            activeEscrow.getUserBalance(address(this), address(tokenWETH)), 0, "User WETH escrow pre-deposit balance"
        );
        assertEq(
            activeEscrow.getUserBalance(address(this), ETH_MOCK_ADDRESS), 0, "User Mock ETH escrow pre-deposit balance"
        );
        assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow pre-balance");

        token.approve(address(activeEscrow), 100 ether);

        vm.expectRevert();
        activeEscrow.depositToken(address(token), 100 ether);

        assertEq(token.balanceOf(address(activeEscrow)), 0 ether, "Escrow post-deposit balance");
        assertEq(
            activeEscrow.getUserBalance(address(this), address(tokenWETH)), 0, "User WETH escrow post-deposit balance"
        );
        assertEq(
            activeEscrow.getUserBalance(address(this), ETH_MOCK_ADDRESS), 0, "User Mock ETH escrow post-deposit balance"
        );
    }

    function test_fuzz_depositETH(uint256 amount) public {
        IERC20 token;
        if (vm.activeFork() == forks[ForkChain.MAINNET]) {
            token = IERC20(MAINNET_WETH);
        } else if (vm.activeFork() == forks[ForkChain.ARBITRUM]) {
            token = IERC20(ARBITRUM_WETH);
        } else {
            revert("Chain not supported");
        }

        amount = bound(amount, 1, 9e26);

        assertEq(activeEscrow.getUserBalance(address(this), address(token)), 0, "User escrow pre-deposit balance");
        assertEq(token.balanceOf(address(activeEscrow)), 0, "Escrow WETH pre-despoit balance");
        assertEq(address(activeEscrow).balance, 0, "Escrow ETH pre-despoit balance");

        activeEscrow.depositETH{value: amount}();

        assertEq(activeEscrow.getUserBalance(address(this), address(token)), amount, "User escrow post-deposit balance");
        assertEq(token.balanceOf(address(activeEscrow)), amount, "Escrow WETH post-despoit balance");
        assertEq(address(activeEscrow).balance, 0, "Escrow ETH post-despoit balance");
    }

    function test_fuzz_withdraw_Token_NoUnwrap(uint256 amountDeposit, uint256 amountWithdraw) public {
        test_fuzz_depositToken(amountDeposit);

        amountDeposit = bound(amountDeposit, 1, 90_000 ether);
        amountWithdraw = bound(amountWithdraw, 1, amountDeposit);

        uint256 tokenLength = tokens[activeFork].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[activeFork][i].token);

            assertEq(
                activeEscrow.getUserBalance(address(this), address(token)),
                amountDeposit,
                "User escrow pre-withdraw balance"
            );
            assertEq(token.balanceOf(address(this)), 0, "User token pre-withdraw balance");
            assertEq(token.balanceOf(address(activeEscrow)), amountDeposit, "Escrow pre-withdraw balance");

            activeEscrow.withdraw(address(token), amountWithdraw, false);

            assertEq(
                activeEscrow.getUserBalance(address(this), address(token)),
                amountDeposit - amountWithdraw,
                "User escrow post-withdraw balance"
            );
            assertEq(
                token.balanceOf(address(activeEscrow)), amountDeposit - amountWithdraw, "Escrow post-withdraw balance"
            );
            assertEq(token.balanceOf(address(this)), amountWithdraw, "User token post-withdraw balance");
        }
    }

    function test_fuzz_withdraw_Token_Unwrap(uint256 amountDeposit, uint256 amountWithdraw) public {
        amountDeposit = bound(amountDeposit, 0.0001 ether, 90_000 ether);
        amountWithdraw = bound(amountWithdraw, 0.0001 ether, amountDeposit);

        amountWithdraw = amountWithdraw > amountDeposit ? amountDeposit : amountWithdraw;

        test_fuzz_depositToken(amountDeposit);

        uint256 tokenLength = tokens[activeFork].length;

        for (uint256 i; i < tokenLength; ++i) {
            IERC20 token = IERC20(tokens[activeFork][i].token);

            IEscrow.Token memory tokenInfo = activeEscrow.getTokenInfo(address(token));

            address activeWETH = activeFork == ForkChain.ARBITRUM ? ARBITRUM_WETH : MAINNET_WETH;
            if (address(token) == activeWETH) {
                continue;
            }

            assertEq(
                activeEscrow.getUserBalance(address(this), address(token)),
                amountDeposit,
                "User escrow pre-withdraw balance"
            );
            assertEq(token.balanceOf(address(this)), 0, "User token pre-withdraw balance");
            assertEq(token.balanceOf(address(activeEscrow)), amountDeposit, "Escrow pre-withdraw balance");

            if (tokenInfo.rebase == address(0)) {
                vm.expectRevert();
                activeEscrow.withdraw(address(token), amountWithdraw, true);

                assertEq(token.balanceOf(address(this)), 0, "User token post-withdraw balance");
                assertEq(
                    activeEscrow.getUserBalance(address(this), address(token)),
                    amountDeposit,
                    "User escrow post-withdraw balance"
                );
                assertEq(token.balanceOf(address(activeEscrow)), amountDeposit, "Escrow post-withdraw balance");
            } else {
                uint256 receiveAmount = activeEscrow.withdraw(address(token), amountWithdraw, true);

                assertEq(token.balanceOf(address(this)), 0, "User token post-withdraw balance");
                assertApproxEqAbs(
                    IERC20(tokenInfo.rebase).balanceOf(address(this)),
                    receiveAmount,
                    10,
                    "User rebase token post-withdraw balance"
                );
                assertEq(
                    activeEscrow.getUserBalance(address(this), address(token)),
                    amountDeposit - amountWithdraw,
                    "User escrow post-withdraw balance"
                );
                assertEq(
                    token.balanceOf(address(activeEscrow)),
                    amountDeposit - amountWithdraw,
                    "Escrow post-withdraw balance"
                );
            }
        }
    }

    function test_fuzz_withdraw_ETH_Unwrap(uint256 amountDeposit, uint256 amountWithdraw) public {
        uint256 initialETHBal = payable(address(this)).balance;

        amountDeposit = bound(amountDeposit, 2 ether, 9e26);
        amountWithdraw = bound(amountWithdraw, 1 ether, amountDeposit);

        if (amountWithdraw > amountDeposit) {
            amountWithdraw = amountDeposit;
        }

        IERC20 token;
        if (vm.activeFork() == forks[ForkChain.MAINNET]) {
            token = IERC20(MAINNET_WETH);
        } else if (vm.activeFork() == forks[ForkChain.ARBITRUM]) {
            token = IERC20(ARBITRUM_WETH);
        } else {
            revert("Chain not supported");
        }

        test_fuzz_depositETH(amountDeposit);

        assertEq(token.balanceOf(address(this)), 0, "User token pre-withdraw balance");
        assertEq(address(this).balance, initialETHBal - amountDeposit, "User ETH pre-withdraw balance");

        assertEq(
            activeEscrow.getUserBalance(address(this), address(token)),
            amountDeposit,
            "User escrow pre-withdraw balance"
        );
        assertEq(token.balanceOf(address(activeEscrow)), amountDeposit, "Escrow pre-withdraw balance");
        assertEq(address(activeEscrow).balance, 0, "Escrow ETH pre-withdraw balance");

        activeEscrow.withdraw(address(token), amountWithdraw, true);

        assertEq(token.balanceOf(address(activeEscrow)), amountDeposit - amountWithdraw, "Escrow post-withdraw balance");
        assertEq(address(activeEscrow).balance, 0, "Escrow ETH post-withdraw balance");

        assertEq(
            activeEscrow.getUserBalance(address(this), address(token)),
            amountDeposit - amountWithdraw,
            "User escrow post-withdraw balance"
        );
        assertEq(token.balanceOf(address(this)), 0, "User token post-withdraw balance");
        assertEq(
            address(this).balance, initialETHBal - (amountDeposit - amountWithdraw), "User ETH post-withdraw balance"
        );
    }

    function _deployMockToken() internal returns (address) {
        return address(new ERC20Mock());
    }

    fallback() external payable {
        if (failReceive) {
            revert("Cannot receive ETH");
        }
    }
}
