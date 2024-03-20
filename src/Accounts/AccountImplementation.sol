// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BeaconProxy} from "openzeppelin-contracts/proxy/beacon/BeaconProxy.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract AccountImplementation is Initializable {
    using SafeERC20 for IERC20;

    error ArrayOutOfBounds();
    error NonWhitelistedToken();

    address public user;
    address[] public tokens;

    constructor() {
        _disableInitializers();
    }

    function initialize(address user_) external initializer {
        user = user_;
    }

    function getAccountTVL() external view returns (uint256 tvl) {
        uint256 length = tokens.length;
        for (uint256 i; i < length;) {
            tvl += IERC20(tokens[i]).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    function depositCollateral(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (IERC20(token).balanceOf(address(this)) == 0) {
            tokens.push(token);
        }
    }

    function withdraw(address token, uint256 amount) external {}

    function _removeToken(address token) internal {
        uint256 length = tokens.length;

        for (uint256 i; i < length;) {
            if (tokens[i] == token) {
                tokens[i] = tokens[length - 1];
                break;
            }

            unchecked {
                ++i;
            }
        }

        tokens.pop();
    }
}
