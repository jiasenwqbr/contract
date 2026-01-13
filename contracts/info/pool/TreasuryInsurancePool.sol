// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
library SafeMath {
    function mul(uint a,uint b) internal pure returns (uint){
        if (a == 0){
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint a,uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a/b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c; 
    }
    function sub(uint a,uint b) internal pure returns (uint){
        assert(b <= a);
        return a - b;
    }
    function add(uint a,uint b) internal pure returns (uint){
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}
interface DepositForRedeem {
    function reduceSalseQuota(address user,uint256 infoAmount) external;
    function getSalseQuotaINFO(address user) external view  returns(uint256);
    function addLiquidityBNBINFO(uint256 amountIn) external  ;
    function getInfo2USDT(uint256 infoAmount) external view returns(uint256);
    function withDrawInfoFromContract(uint256 amount,address to) external;
    function redeem(uint256 bnbAmount) external  payable returns(uint256);
}

contract TreasuryInsurancePool  is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
         using SafeMath for uint;
        using SafeERC20Upgradeable for IERC20Upgradeable;
        bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
        /// @custom:oz-upgrades-unsafe-allow constructor
        constructor() {
            _disableInitializers();
        }

        function _authorizeUpgrade(
            address newImplementation
        ) internal override onlyRole(MANAGE_ROLE) {}

        function initialize(address _infoAddress,address _swapRouterAddress
        ) public initializer {
            __AccessControlEnumerable_init();
            __ReentrancyGuard_init();
            __UUPSUpgradeable_init();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(MANAGE_ROLE, msg.sender);
            _grantRole(OPERATOR, msg.sender);
            infoAddress = _infoAddress;
            swapRouterAddress = _swapRouterAddress;


        }

    event WithdrawErc20(address token,address operator,address to,uint256 amount,uint256 createTime);
    event WithdrawBNB(address operator,address to,uint256 amount,uint256 createTime);
    event Redeem(address operator,uint256 bnbBalance,uint256 redeemAmount,uint256 createTime);

    uint256 public redeemRatio;
    uint256 public constant DENOMINATOR = 1000; 
    address public redeemToAddress;
    bytes32 public constant OPERATOR = keccak256("OPERATOR_ROLE");

    address swapRouterAddress;
    address infoAddress;
    address depositContractAddress;


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

    function redeemAndBurn() external onlyRole(MANAGE_ROLE) {
        uint256 bnbBalance = payable(address(this)).balance;
        uint256 redeemAmount = bnbBalance*redeemRatio/DENOMINATOR;
        // 转账
        // (bool success, ) = redeemToAddress.call{value: redeemAmount}("");
        // require(success, "BNB transfer failed");
        // 购买INFO
        uint256 infoAmount =  swapINFO(redeemAmount,address(this));
        IERC20(infoAddress).transfer(redeemToAddress,infoAmount);
        emit Redeem(msg.sender,bnbBalance,infoAmount,block.timestamp);
    }

    function setRedeemToAddress(address _redeemToAddress)  external onlyRole(MANAGE_ROLE) {
        require(_redeemToAddress!=address(0));
        redeemToAddress = _redeemToAddress;
    }

    function  redeem() external onlyRole(MANAGE_ROLE) {
        uint256 bnbBalance = payable(address(this)).balance;
        uint256 redeemAmount = bnbBalance*redeemRatio/DENOMINATOR;
        // 转账
        (bool success, ) = depositContractAddress.call{value: redeemAmount}("");
        require(success, "BNB transfer failed");
        // 购买INFO
        uint256 infoAmount =  DepositForRedeem(depositContractAddress).redeem(redeemAmount);
        IERC20(infoAddress).transfer(redeemToAddress,infoAmount);
        emit Redeem(msg.sender,bnbBalance,infoAmount,block.timestamp);
    }


    receive() external payable {}


    function swapINFO(uint256 bnbAmount,address receive0Address) internal returns(uint256) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouterAddress);
        address factory = swapRouter.factory();
        require(factory != address(0), "INVALID_ROUTER");
        // BNB -> INFO
        address[] memory path1 = new address[](2);
        path1[0] = swapRouter.WETH();
        path1[1] = infoAddress;
        uint256 beforeInfoBalance = IERC20(infoAddress).balanceOf(address(this));
        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0,
            path1,
            address(this),
            block.timestamp + 300
        );

        uint256 afterInfoBalance = IERC20(infoAddress).balanceOf(address(this));
        uint256 infoAmount = afterInfoBalance.sub(beforeInfoBalance);
        
        require(infoAmount > 0, "NO_INFO_RECEIVED");
        IERC20(infoAddress).transfer(receive0Address,infoAmount);
        return infoAmount;
    }

    function setDepositContractAddress(address depositAddress) public onlyRole(MANAGE_ROLE){
        require(depositAddress != address(0),"0 address");
        depositContractAddress = depositAddress;
    }

    



}