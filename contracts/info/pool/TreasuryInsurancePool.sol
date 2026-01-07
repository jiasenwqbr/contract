// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract TreasuryInsurancePool  is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
        using SafeERC20Upgradeable for IERC20Upgradeable;
        bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
        /// @custom:oz-upgrades-unsafe-allow constructor
        constructor() {
            _disableInitializers();
        }

        function _authorizeUpgrade(
            address newImplementation
        ) internal override onlyRole(MANAGE_ROLE) {}

        function initialize(
        ) public initializer {
            __AccessControlEnumerable_init();
            __ReentrancyGuard_init();
            __UUPSUpgradeable_init();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(MANAGE_ROLE, msg.sender);
        }

    event WithdrawErc20(address token,address operator,address to,uint256 amount,uint256 createTime);
    event WithdrawBNB(address operator,address to,uint256 amount,uint256 createTime);
    event Redeem(address operator,uint256 bnbBalance,uint256 redeemAmount,uint256 createTime);

    uint256 public redeemRatio;
    uint256 public constant DENOMINATOR = 1000; 
    address public redeemToAddress;

    function balance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function withdrawErc20(
        address token,
        address to,
        uint256 amount
    ) public onlyRole(MANAGE_ROLE) {
        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(
            address(this)
        );
        require(tokenBalance >= amount, "ERROR:INSUFFICIENT");
        IERC20Upgradeable(token).safeTransfer(to, amount);
        emit WithdrawErc20(token,msg.sender,to,amount,block.timestamp);
    }

    function withdrawBNB(
        address to,
        uint256 amount
    ) public onlyRole(MANAGE_ROLE) {
        uint256 bnbBalance = payable(address(this)).balance;
        require(bnbBalance >= amount, "ERROR:INSUFFICIENT");
        payable(to).transfer(amount);
        emit WithdrawBNB(msg.sender,to,amount,block.timestamp);
    }

    function setRedeemRatio(uint256 ratio) external onlyRole(MANAGE_ROLE) {
        require(ratio <= DENOMINATOR,"ratio is > DENOMINATOR");
        redeemRatio = ratio;
    }

    function redeem() external onlyRole(MANAGE_ROLE) {
        require(redeemToAddress!=address(0));
        uint256 bnbBalance = payable(address(this)).balance;
        uint256 redeemAmount = bnbBalance*redeemRatio/bnbBalance;
        payable(redeemToAddress).transfer(redeemAmount);
        emit Redeem(msg.sender,bnbBalance,redeemAmount,block.timestamp);
    }

    function setRedeemToAddress(address _redeemToAddress)  external onlyRole(MANAGE_ROLE) {
        require(_redeemToAddress!=address(0));
        redeemToAddress = _redeemToAddress;
    }


}