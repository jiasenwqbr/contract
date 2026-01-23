// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
interface IRecommendation {
    function getUserInfo(address user) external view returns (address referrer,uint256 registrationTime,address[] memory directReferrals,address[] memory referralChain);
}
interface INFOC {
    function transferFromContract(address to, uint256 amount) external;
}
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
contract DepositContract is 
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable{
        using SafeMath for uint;
        bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
        bytes32 public constant INFO_ROLE = keccak256("INFO_ROLE");
        function initialize(
            address _usdt,
            address _infoAddress,
            address _swapRouterAddress,
            address[4] memory _depositAllocation,
            uint256[4] memory _depositAllocationRatio)public initializer {
            __AccessControlEnumerable_init();
            __ReentrancyGuard_init();
            __UUPSUpgradeable_init();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(MANAGE_ROLE, msg.sender);
            _grantRole(INFO_ROLE,_infoAddress);
            usdt = _usdt;
            infoAddress = _infoAddress;
            swapRouterAddress = _swapRouterAddress;
            depositAllocation = _depositAllocation;
            depositAllocationRatio = _depositAllocationRatio;
        }
        /// @custom:oz-upgrades-unsafe-allow constructor
        constructor() {
            _disableInitializers();
        }

        function _authorizeUpgrade(
            address newImplementation
        ) internal override onlyRole(MANAGE_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    /////////////////////////////////////////////////////////////*/

    address usdt;
    address infoAddress;
    address swapRouterAddress;
    address[4] depositAllocation;
    uint256[4] depositAllocationRatio;
    uint256 public constant DENOMINATOR = 1000; 
    mapping(address => uint256) salseQuota;
    address public recommendContractAddress;
    address public lpReceiverAddress;
    address public redeenAddress;
    uint256[2] public depositLimit; 


    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address userAddress,address usdt,uint256 usdtAmount,uint256 bnbAmount,uint256 swapedBnbAmount,address receive0,uint256 infoAmount,address receiver1,uint256 receiver1Amount,address receiver2,uint256 receiver2Amount,address receiver3,uint256 receiver3Amount,uint256 usdValue,uint256 userSalseQuota,uint256 createTime);
    event DepositaddLiquidity(uint256 amountIn,uint256 swapAmount,address lpReceiverAddress);
    event AddLiquidityBNBINFO(uint256 beforeInfoBalance,uint256 afterInfoBalance,uint256 incr);
    event TestSwapINFO(uint256 bnbamount,address receiver);
    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(address _usdt,uint256 amount,uint256 usdValue) public nonReentrant payable {
        (address referAddress,,,) = IRecommendation(recommendContractAddress).getUserInfo(msg.sender);
        require(referAddress != address(0),"referAddress is 0");
        require(usdValue > 0,"usdValue should > 0");
        uint256 bnbAmount;
        if (_usdt == address(0)){
            require(msg.value > 0,"amount should > 0");
            require(amount > 0,"amount should > 0");
            bnbAmount = msg.value;
            // 获取bnb的usdt价值
            usdValue = getbnb2USDT(msg.value);
        } else {
            require(_usdt == usdt,"Invalid usdt address");
            require(amount ==  usdValue,"usdValue is invalid");
            bnbAmount = buyBNB(usdt, amount, 0);
        }
        require(usdValue >= depositLimit[0] && usdValue <= depositLimit[1],"usdValue should >= min and <= max");
        uint256 userSalseQuota = salseQuota[msg.sender].add(usdValue.mul(3));
        salseQuota[msg.sender] = userSalseQuota;
        salseQuota[address(this)] = salseQuota[address(this)].add(usdValue.mul(3));
        // 50% buy INFO
        address receive0 = depositAllocation[0];

        uint256 beforeInfoBalance = IERC20(infoAddress).balanceOf(infoAddress);
        emit TestSwapINFO(bnbAmount.mul(depositAllocationRatio[0]).div(DENOMINATOR),receive0);
        uint256 infoAmount = swapINFO(bnbAmount.mul(depositAllocationRatio[0]).div(DENOMINATOR),receive0);
        uint256 afterInfoBalance = IERC20(infoAddress).balanceOf(infoAddress);
        uint256 incr = afterInfoBalance - beforeInfoBalance;
        if (incr > 0){
            //IERC20(infoAddress).transferFrom(infoAddress,address(this),incr);
            
            INFOC(infoAddress).transferFromContract(address(this),incr);
            addLiquidityBNBINFO2(incr); 
        }

        emit AddLiquidityBNBINFO(beforeInfoBalance,afterInfoBalance,incr);
    
        // 35% Treasury insurance pool (contract)
        address receiver1 = depositAllocation[1];
        uint256 receiver1Amount = bnbAmount.mul(depositAllocationRatio[1]).div(DENOMINATOR);
        (bool ok1, ) = receiver1.call{value: receiver1Amount}("");
        require(ok1, "receiver1 BNB transfer failed");
        // payable(receiver1).transfer(receiver1Amount);
        // 10% S1
        address receiver2 = depositAllocation[2];
        uint256 receiver2Amount = bnbAmount.mul(depositAllocationRatio[2]).div(DENOMINATOR);
        // payable(receiver2).transfer(receiver2Amount);
        (bool ok2, ) = receiver2.call{value: receiver2Amount}("");
        require(ok2, "receiver2 BNB transfer failed");
        // 5% Genesis Node Community Weighted Dividend
        address receiver3 = depositAllocation[3];
        uint256 receiver3Amount = bnbAmount.mul(depositAllocationRatio[3]).div(DENOMINATOR);
        // payable(receiver3).transfer(receiver3Amount);
        (bool ok3, ) = receiver3.call{value: receiver3Amount}("");
        require(ok3, "receiver3 BNB transfer failed");

        
        emit Deposit(msg.sender,_usdt,amount,msg.value,bnbAmount,receive0,infoAmount,receiver1,receiver1Amount,receiver2,receiver2Amount,receiver3,receiver3Amount,usdValue,userSalseQuota,block.timestamp);

    }

    function buyBNB(address usdtAddress, uint256 amountIn, uint256 amountOutMin) internal returns(uint256) {
       
        // 1. 先从用户拉 USDT
        SafeERC20.safeTransferFrom(
            IERC20(usdtAddress),
            msg.sender,
            address(this),
            amountIn
        );

        // 2. 再授权 Router
        SafeERC20.safeApprove(
            IERC20(usdtAddress),
            swapRouterAddress,
            0
        );
        SafeERC20.safeApprove(
            IERC20(usdtAddress),
            swapRouterAddress,
            amountIn
        );
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouterAddress);
        // 2. USDT -> WETH
        address[] memory path1 = new address[](2);
        path1[0] = usdtAddress;
        path1[1] = swapRouter.WETH();
        
        uint256 beforeETHBalance = address(this).balance;
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path1,
            address(this),
            block.timestamp + 300
        );
        uint256 afterETHBalance = address(this).balance;


        // swap出来的bnb
        uint256 ethReceived = afterETHBalance.sub(beforeETHBalance);
        require(ethReceived > 0, "No ETH received");
        return ethReceived;
    }


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

    function setParams(address _usdt,address _infoAddress,address _swapRouterAddress,address[4] memory _depositAllocation, uint256[4] memory _depositAllocationRatio) public onlyRole(MANAGE_ROLE) {
        usdt = _usdt;
        infoAddress = _infoAddress;
        swapRouterAddress = _swapRouterAddress;
        depositAllocation = _depositAllocation;
        depositAllocationRatio = _depositAllocationRatio;
    }

    function getParams() public view returns(address,address,address,address[4] memory,uint256[4] memory){
        return (usdt,infoAddress,swapRouterAddress,depositAllocation,depositAllocationRatio);
    }
    function getDepositAllocation() public view returns(address,address,address,uint256[4] memory,address[4] memory) {
        return (usdt,infoAddress,swapRouterAddress,depositAllocationRatio,depositAllocation);
    }


    function getSalseQuotaUSDT(address user) public view returns(uint256){
        return salseQuota[user];
    }

    function getSalseQuotaINFO(address user) public view  returns(uint256){
        return getUSDT2Info(salseQuota[user]);
    }

    function reduceSalseQuota(address user,uint256 infoAmount) public onlyRole(INFO_ROLE) {
        uint256 usdtAmount = getInfo2USDT(infoAmount);
        require(usdtAmount <= salseQuota[user],"Exceeding the limit");
        // reduce salse quota
        salseQuota[user] = salseQuota[user].sub(usdtAmount);
    }

    function addSalseQuota(address user,uint256 infoAmount) public onlyRole(MANAGE_ROLE) {
        uint256 usdtAmount = getInfo2USDT(infoAmount);
        // require(usdtAmount <= salseQuota[user],"Exceeding the limit");
        // reduce salse quota
        salseQuota[user] = salseQuota[user].add(usdtAmount);
    }
    function addSalseQuotaUSDT(address user,uint256 usdtAmount) public onlyRole(MANAGE_ROLE) {
        salseQuota[user] = salseQuota[user].add(usdtAmount);
    }

    function reduceSalseQuotaUSDT(address user,uint256 usdtAmount) public onlyRole(MANAGE_ROLE) {
        salseQuota[user] = salseQuota[user].sub(usdtAmount);
    }

    function getbnb2USDT(uint256 amount) public view returns(uint256) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouterAddress);
        // bnb -> usdt
        address[] memory path2 = new address[](2);
        path2[0] = swapRouter.WETH();
        path2[1] = usdt;

        uint[] memory amounts2 = swapRouter.getAmountsOut(amount, path2);
        uint256 usdtAmount = amounts2[1];
        require(usdtAmount > 0, "BNB->USDT quote failed");
        
        return usdtAmount;
    }

    function getInfo2USDT(uint256 infoAmount) public view returns(uint256) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouterAddress);
        // info -> bnb
        address[] memory path1 = new address[](2);
        path1[0] = infoAddress;
        path1[1] = swapRouter.WETH();
        uint[] memory amounts1 = swapRouter.getAmountsOut(infoAmount, path1);
        uint256 bnbAmount = amounts1[1];
        require(bnbAmount > 0, "INFO->BNB quote failed");
        // bnb -> usdt
        address[] memory path2 = new address[](2);
        path2[0] = swapRouter.WETH();
        path2[1] = usdt;

        uint[] memory amounts2 = swapRouter.getAmountsOut(bnbAmount, path2);
        uint256 usdtAmount = amounts2[1];
        require(usdtAmount > 0, "BNB->USDT quote failed");
        
        return usdtAmount;
    }

    function getUSDT2Info(uint256 usdtAmount) internal view returns(uint256) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouterAddress);
        // usdt -> bnb
        address[] memory path1 = new address[](2);
        path1[0] = usdt;
        path1[1] = swapRouter.WETH();
        uint[] memory amounts1 = swapRouter.getAmountsOut(usdtAmount, path1);
        uint256 bnbAmount = amounts1[1];
        require(bnbAmount > 0, "USDT->BNB quote failed");

        // bnb -> info
        address[] memory path2 = new address[](2);
        path2[0] = swapRouter.WETH();
        path2[1] = infoAddress;
        uint[] memory amounts2 = swapRouter.getAmountsOut(bnbAmount, path2);
        uint256 infoAmount = amounts2[1];
        require(infoAmount > 0, "BNB->INFO quote failed");

        return infoAmount;
    }

    
    function addLiquidityBNBINFO2(uint256 amountIn) internal{
        
        
        // IERC20(infoAddress).transferFrom(
        //     msg.sender,
        //     address(this),
        //     amountIn
        // );
        IUniswapV2Router02  swapRouter = IUniswapV2Router02(swapRouterAddress);
        // 1. increase allowance
        IERC20(infoAddress).approve(swapRouterAddress, amountIn);
        uint256 swapAmount =  amountIn/2;
        address[] memory path = new address[](2);
        path[0] = infoAddress;
        path[1] = swapRouter.WETH();

        // 记录兑换前的 BNB 余额
        uint256 bnbBalanceBefore = address(this).balance;
        
        // 执行兑换
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0, // 接受任意数量的 BNB（实际使用时应设置最小数量）
            path,
            address(this),
            block.timestamp + 300 // 5分钟截止时间
        );
        // 计算收到的 BNB 数量
        uint256 bnbReceived = address(this).balance - bnbBalanceBefore;
        emit DepositaddLiquidity(amountIn,bnbReceived,lpReceiverAddress);
        if (bnbReceived>0){
             _addLiquidity(amountIn - swapAmount, bnbReceived);
        }
       
       
    }


    // 内部函数：添加流动性
    function _addLiquidity(uint256 infoAmount, uint256 bnbAmount) internal {
        // 批准 Router 使用 INFO（如果之前没批准或额度不够）
        IERC20(infoAddress).approve(swapRouterAddress, infoAmount);
        IUniswapV2Router02  swapRouter = IUniswapV2Router02(swapRouterAddress);
        // 添加流动性
        swapRouter.addLiquidityETH{value: bnbAmount}(
            infoAddress,
            infoAmount,
            0, // INFO 最小数量（实际使用时应设置合理值）
            0, // BNB 最小数量（实际使用时应设置合理值）
            lpReceiverAddress, // LP Token 接收者
            block.timestamp + 300 // 5分钟截止时间
        );
        
    }

    function setPara( address _usdt,
        address _infoAddress,
        address _swapRouterAddress,
        address _recommendContractAddress,
        address _lpReceiverAddress) external onlyRole(MANAGE_ROLE) {
            require(_usdt != address(0),"0 address");
            require(_infoAddress != address(0),"0 address");
            require(_swapRouterAddress != address(0),"0 address");
            require(_recommendContractAddress != address(0),"0 address");
            require(_lpReceiverAddress != address(0),"0 address");
            usdt = _usdt;
            infoAddress = _infoAddress;
            swapRouterAddress = _swapRouterAddress;
            recommendContractAddress = _recommendContractAddress;
            lpReceiverAddress = _lpReceiverAddress;
    }

    
    function redeem(uint256 bnbAmount) external  payable  onlyRole(MANAGE_ROLE) returns(uint256){
        
        uint256 usdValue = getbnb2USDT(bnbAmount);
        uint256 userSalseQuota = salseQuota[msg.sender].add(usdValue.mul(3));
        salseQuota[msg.sender] = userSalseQuota;
        salseQuota[address(this)] = salseQuota[address(this)].add(usdValue.mul(3));

       
        uint256 beforeInfoBalance = IERC20(infoAddress).balanceOf(infoAddress);
        uint256 infoAmount = swapINFO(bnbAmount,redeenAddress);
        uint256 afterInfoBalance = IERC20(infoAddress).balanceOf(infoAddress);
        uint256 incr = afterInfoBalance - beforeInfoBalance;
        if (incr > 0){
            //IERC20(infoAddress).transferFrom(infoAddress,address(this),incr);
            
            INFOC(infoAddress).transferFromContract(address(this),incr);
            addLiquidityBNBINFO2(incr); 
        }

        emit AddLiquidityBNBINFO(beforeInfoBalance,afterInfoBalance,incr);
    
        return infoAmount;
       
    }

    function setRedeenAddress(address _redeemAddress) public onlyRole(MANAGE_ROLE) {
        require(_redeemAddress != address(0),"0 address");
        redeenAddress = _redeemAddress;
    }

    function setDepositLimit(uint256 _min,uint256 _max)  public onlyRole(MANAGE_ROLE) {
        depositLimit[0] = _min;
        depositLimit[1] = _max;
    }

    receive() external payable {}

    fallback() external payable {}



    



}
