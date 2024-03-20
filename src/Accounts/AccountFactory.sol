// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BeaconProxy} from "openzeppelin-contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "openzeppelin-contracts/proxy/beacon/UpgradeableBeacon.sol";

import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract AccountFactory is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    struct Account {
        address account;
    }

    error ZeroAddress();
    error ExistingAccount();

    address public beacon;

    // User -> Account
    mapping(address => Account) public accounts;

    constructor() {
        _disableInitializers();
    }

    function initialize(address beacon_) external initializer {
        if (beacon_ == address(0)) revert ZeroAddress();

        beacon = beacon_;
    }

    function getAccount(address user) external view returns (address) {
        return accounts[user].account;
    }

    function createAccount(address user) public returns (address) {
        if (accounts[user].account != address(0)) revert ExistingAccount();

        address newAccount = address(new BeaconProxy(beacon, abi.encodePacked("")));

        accounts[user] = Account({account: newAccount});

        return newAccount;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
