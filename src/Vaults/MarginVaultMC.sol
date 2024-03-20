// import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
// import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";

// contract MarginVault is Initializable {
//     using SafeERC20 for IERC20;

//     error ZeroAddress();
//     error AssetNotWhitelisted();
//     error DepositCannotBeZero();

//     struct User {
//         uint256 balance;
//         int256 rewardDebt;
//     }

//     struct Vault {
//         bool whitelisted;
//         uint128 accRewards;
//         uint128 totalBalance;
//         uint128 allocatedBalance;
//     }

//     uint256 constant REWARDS_DENOM = 1e12;

//     // User -> Token - Info
//     mapping(address => mapping(address => User)) public users;
//     mapping(address => Vault) public vaults;

//     address[] public whitelistedAssets;

//     constructor() public {
//         _disableInitializers();
//     }

//     function initialize(address[] calldata underlyingAssets) public initializer {
//         uint256 length = underlyingAssets.length;

//         for (uint256 i; i < length;) {
//             if (underlyingAssets[i] == address(0)) revert ZeroAddress();

//             whitelistedAssets.push(underlyingAsset[i]);
//             vaults[underlyingAssets[i]].whitelisted = true;

//             unchecked {
//                 ++i;
//             }
//         }
//     }

//     function deposit(address token, uint256 amount) external {
//         Vault memory vault = vaults[token];

//         if (!vault.whitelisted) revert AssetNotWhitelisted();
//         if (amount == 0) revert DepositCannotBeZero();

//         IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

//         users[token].balance += amount;
//     }

//     function withdraw(address token, uint256 amount) external {
//         User memory user = users[msg.sender];

//         IERC20(token).safeTransfer(msg.sender, amount + reward);
//     }

//     function takeLoan() external {}

//     function payInterest() external {}
// }
