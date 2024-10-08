import {IBracketEscrow} from "./interfaces/IBracketEscrow.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract BracketSwapRouter {
    error SlippageExceeded();
    error SwapFailed();
    error ZeroAddress();
    error ZeroAmount();

    address public immutable swapRouter;
    IBracketEscrow public immutable bracketEscrow;

    constructor(address _bracketEscrow, address _swapRouter) {
        if (_bracketEscrow == address(0)) revert ZeroAddress();
        if (_swapRouter == address(0)) revert ZeroAddress();
        bracketEscrow = IBracketEscrow(_bracketEscrow);
        swapRouter = _swapRouter;
    }

    function swapEth(address token, uint256 minOutput, bytes memory data) external payable {
        if (msg.value == 0) revert ZeroAmount();

        uint256 preBal = IERC20(token).balanceOf(address(this));

        (bool success,) = swapRouter.call{value: msg.value}(data);
        if (!success) revert SwapFailed();

        uint256 amountOut = IERC20(token).balanceOf(address(this)) - preBal;
        if (amountOut < minOutput) revert SlippageExceeded();

        IERC20(token).approve(address(bracketEscrow), amountOut);
        bracketEscrow.depositToken(msg.sender, token, amountOut);
    }
}
