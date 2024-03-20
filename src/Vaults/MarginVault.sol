import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC4626Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";

contract MarginVault is Initializable, ERC20Upgradeable, ERC4626Upgradeable {
    uint256 public allocatedAmt;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_, address asset_) external {
        __ERC20_init(name_, symbol_);
        __ERC4626_init(asset_);
    }

    function allocationRate(int256 offset) public view returns (uint256) {
        uint256 rate = (allocatedAmt + offset) * 10_00 / totalAssets();
    }

    // We need to be very careful with the liquidations.
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + allocatedAmt;
    }

    // User can front-run rewards by depositing just before and then withdrawing, or front-run loses by withdrawing just before the loss happens.
    // Because of this we need to delay withdrawal. However, while users wait to withdraw, do we keep accruing or not?
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        int256 amount = allocationRate(-convertToAssets(shares));
        if (amount >= 99) {
            revert("Vault fully alocated, withdrawal is not possible");
        } else if (amount >= 70) {
            revert("Vault allocation above 70 percent, instant withdrawal not available");
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
