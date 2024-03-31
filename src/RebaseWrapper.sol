// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract RebaseWrapper is Initializable, Ownable2StepUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    mapping(address => address) public wrappers;

    function wrap(address token, uint256 amount) external returns (uint256) {
        address wrapper = wrappers[token];
    }

    function unwrap(address token, uint256 amount) external returns (uint256) {}

    function isWrapped() external returns (address) {}

    function _authorizeUpgrade(address) internal override {}
}
