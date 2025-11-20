// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Extremely simple LP locker
// - Anyone can send LP (or any ERC20) tokens to the contract using transfer
// - Contract owner (admin) can withdraw ALL LP at any time
// - Public can view token balances in the contract
// No per-user tracking, no deposit function, no withdraw for users

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleLPLocker is Ownable {
    using SafeERC20 for IERC20;

    constructor() {}

    // Anyone can transfer tokens directly to the contract address
    // No need for deposit() function


    function balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

   
    function adminWithdraw(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero address");
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice Admin withdraw all tokens of a specific LP
     */
    function adminWithdrawAll(address token, address to) external onlyOwner {
        require(to != address(0), "zero address");
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, bal);
    }
}