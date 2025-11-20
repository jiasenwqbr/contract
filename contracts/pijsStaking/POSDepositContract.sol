// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Standard Deposit Contract for PoS
 * @dev 通用PoS存款合约标准
 */
contract POSDepositContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // 存款信息结构体
    struct Deposit {
        address depositor;
        uint256 amount;
        uint256 depositTime;
        uint256 unlockTime;
        bool withdrawn;
    }
    
    // 质押代币
    IERC20 public stakingToken;
    
    // 最小和最大存款金额
    uint256 public minDepositAmount;
    uint256 public maxDepositAmount;
    
    // 锁定周期
    uint256 public lockPeriod;
    
    // 存款记录
    mapping(address => Deposit[]) public deposits;
    mapping(address => uint256) public totalDeposited;
    
    // 事件
    event Deposited(address indexed depositor, uint256 amount, uint256 depositId, uint256 unlockTime);
    event Withdrawn(address indexed depositor, uint256 amount, uint256 depositId);
    event EmergencyWithdraw(address indexed depositor, uint256 amount, uint256 depositId);
    event AdminRecoverToken(address indexed token, uint256 amount);
    
    constructor(
        address _stakingToken,
        uint256 _minDepositAmount,
        uint256 _maxDepositAmount,
        uint256 _lockPeriod
    ) {
        require(_stakingToken != address(0), "Invalid staking token");
        stakingToken = IERC20(_stakingToken);
        minDepositAmount = _minDepositAmount;
        maxDepositAmount = _maxDepositAmount;
        lockPeriod = _lockPeriod;
    }
    
    /**
     * @notice 存款函数
     * @param amount 存款金额
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount >= minDepositAmount, "Amount below minimum");
        require(amount <= maxDepositAmount, "Amount exceeds maximum");
        
        // 检查总存款限额
        uint256 newTotal = totalDeposited[msg.sender] + amount;
        require(newTotal <= maxDepositAmount, "Total deposit exceeds maximum");
        
        // 转账代币
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // 创建存款记录
        uint256 depositId = deposits[msg.sender].length;
        uint256 unlockTime = block.timestamp + lockPeriod;
        
        deposits[msg.sender].push(Deposit({
            depositor: msg.sender,
            amount: amount,
            depositTime: block.timestamp,
            unlockTime: unlockTime,
            withdrawn: false
        }));
        
        totalDeposited[msg.sender] = newTotal;
        
        emit Deposited(msg.sender, amount, depositId, unlockTime);
    }
    
    /**
     * @notice 提取存款
     * @param depositId 存款ID
     */
    function withdraw(uint256 depositId) external nonReentrant {
        Deposit storage userDeposit = deposits[msg.sender][depositId];
        
        require(!userDeposit.withdrawn, "Already withdrawn");
        require(block.timestamp >= userDeposit.unlockTime, "Lock period not ended");
        
        uint256 amount = userDeposit.amount;
        userDeposit.withdrawn = true;
        totalDeposited[msg.sender] -= amount;
        
        // 返还代币
        stakingToken.safeTransfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount, depositId);
    }
    
    /**
     * @notice 紧急提取（有惩罚）
     * @param depositId 存款ID
     * @param penaltyRate 惩罚率（1000 = 10%）
     */
    function emergencyWithdraw(uint256 depositId, uint256 penaltyRate) external nonReentrant {
        require(penaltyRate <= 3000, "Penalty too high"); // 最大30%惩罚
        
        Deposit storage userDeposit = deposits[msg.sender][depositId];
        
        require(!userDeposit.withdrawn, "Already withdrawn");
        
        uint256 amount = userDeposit.amount;
        uint256 penalty = (amount * penaltyRate) / 10000;
        uint256 returnedAmount = amount - penalty;
        
        userDeposit.withdrawn = true;
        totalDeposited[msg.sender] -= amount;
        
        // 返还扣除惩罚后的金额
        stakingToken.safeTransfer(msg.sender, returnedAmount);
        
        // 惩罚金额留在合约中，可由管理员处理
        emit EmergencyWithdraw(msg.sender, returnedAmount, depositId);
    }
    
    /**
     * @notice 获取用户存款信息
     */
    function getUserDeposits(address user) external view returns (Deposit[] memory) {
        return deposits[user];
    }
    
    /**
     * @notice 获取用户存款总数
     */
    function getUserTotalDeposits(address user) external view returns (uint256) {
        return totalDeposited[user];
    }
    
    /**
     * @notice 管理员恢复误转的代币
     */
    function recoverToken(address token, uint256 amount) external onlyOwner {
        require(token != address(stakingToken), "Cannot recover staking token");
        IERC20(token).safeTransfer(owner(), amount);
        emit AdminRecoverToken(token, amount);
    }
    
    /**
     * @notice 更新存款参数
     */
    function updateDepositParams(
        uint256 _minDepositAmount,
        uint256 _maxDepositAmount,
        uint256 _lockPeriod
    ) external onlyOwner {
        minDepositAmount = _minDepositAmount;
        maxDepositAmount = _maxDepositAmount;
        lockPeriod = _lockPeriod;
    }
}