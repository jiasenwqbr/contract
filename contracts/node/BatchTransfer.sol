// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title BatchTransferUpgradeable
 * @dev 可升级的ERC20批量转账合约
 * 使用UUPS代理模式，支持合约升级
 */
contract BatchTransferUpgradeable is 
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;

    // 事件定义
    event BatchTransferSingleToken(
        address indexed token,
        address indexed sender,
        uint256 totalTransferred,
        uint256 recipientCount
    );

    event BatchTransferMultiToken(
        address indexed sender,
        uint256 totalTransactions,
        uint256 uniqueTokenCount
    );

    event TokenSwept(address indexed token, address indexed to, uint256 amount);
    event EmergencyStop(bool stopped);
    event FeeCollected(address indexed collector, uint256 amount);
    event ContractUpgraded(address newImplementation);
    event BatchLimitUpdated(uint256 newLimit);
    event  BatchTransferDifferentAmounts(address token,address caller,address[] recipients,uint256[] amounts,uint256 totalAmount,uint256 recipientsCount,uint256 timestamp);
    event  BatchTransferDifferentTokenAmounts(address[] token,address caller,address[] recipients,uint256[] amounts,uint256 recipientsCount,uint256 timestamp);
    event BatchTransferSameAmount(address token, address caller,address[] recipients,uint256 amount,uint256 totalAmount,uint256 recipientsCount,uint256 timestamp);
    

    // 状态变量 - 注意：不要修改现有变量的顺序，只能追加新变量
    bool public stopped;
    uint256 public batchLimit;

    // 新增状态变量（在升级时可以添加）
    mapping(address => uint256) public userTotalTransferred;
    mapping(address => mapping(address => uint256)) public userTokenTransferred;
    uint256 public totalTransactions;
    uint256 public totalVolume;

  
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }

    /**
     * @dev 初始化函数 - 替代构造函数
     * @param _batchLimit 批量转账限制
     */
    function initialize(
        uint256 _batchLimit
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        batchLimit = _batchLimit;
        stopped = false;
    }

    // UUPS 升级授权 - 只有所有者可以升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        emit ContractUpgraded(newImplementation);
    }

    /**
     * @dev 单币种批量转账 - 相同金额
     */
    function batchTransferSameAmount(
        address token,
        address[] calldata recipients,
        uint256 amount
    ) external nonReentrant whenNotStopped {
        _validateBatchInput(token, recipients.length);
        require(amount > 0, "Amount must be positive");

        IERC20Upgradeable tokenContract = IERC20Upgradeable(token);
        uint256 totalAmount = amount * recipients.length;
        
        _checkAllowanceAndBalance(tokenContract, totalAmount);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(
                tokenContract.transferFrom(msg.sender, recipients[i], amount),
                "Transfer failed"
            );
        }

        _updateStatistics(msg.sender, token, totalAmount, recipients.length);

        // emit BatchTransferSingleToken(token, msg.sender, totalAmount, recipients.length);
        emit BatchTransferSameAmount(token, msg.sender, recipients, amount,totalAmount,recipients.length,block.timestamp);
    }

    /**
     * @dev 单币种批量转账 - 不同金额
     */
    function batchTransferDifferentAmounts(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotStopped {
        _validateBatchInput(token, recipients.length);
        require(recipients.length == amounts.length, "Array length mismatch");

        IERC20Upgradeable tokenContract = IERC20Upgradeable(token);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "Amount must be positive");
            require(recipients[i] != address(0), "Invalid recipient");
            totalAmount += amounts[i];
        }

        _checkAllowanceAndBalance(tokenContract, totalAmount);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                tokenContract.transferFrom(msg.sender, recipients[i], amounts[i]),
                "Transfer failed"
            );
        }

        _updateStatistics(msg.sender, token, totalAmount, recipients.length);
       //  emit BatchTransferSingleToken(token, msg.sender, totalAmount, recipients.length);
        emit BatchTransferDifferentAmounts(token, msg.sender, recipients, amounts,totalAmount,recipients.length,block.timestamp);
    }

    /**
     * @dev 多币种批量转账
     */
    function batchTransferMultipleTokens(
        address[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotStopped {
        require(tokens.length > 0, "No tokens");
        require(tokens.length == recipients.length, "Array length mismatch");
        require(tokens.length == amounts.length, "Array length mismatch");
        require(tokens.length <= batchLimit, "Batch too large");

        uint256 uniqueTokenCount = 0;
        address lastToken = address(0);
        uint256 totalTransferred = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "Invalid token address");
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Amount must be positive");

            IERC20Upgradeable tokenContract = IERC20Upgradeable(tokens[i]);

            _checkAllowanceAndBalance(tokenContract, amounts[i]);

            require(
                tokenContract.transferFrom(msg.sender, recipients[i], amounts[i]),
                "Transfer failed"
            );

            if (tokens[i] != lastToken) {
                uniqueTokenCount++;
                lastToken = tokens[i];
            }

            totalTransferred += amounts[i];
            _updateUserStatistics(msg.sender, tokens[i], amounts[i]);
        }

        totalTransactions += tokens.length;
        totalVolume += totalTransferred;
        
        // emit BatchTransferMultiToken(msg.sender, tokens.length, uniqueTokenCount);
        emit BatchTransferDifferentTokenAmounts(tokens, msg.sender, recipients, amounts,recipients.length,block.timestamp);
    }

    /**
     * @dev 内部函数：验证批量输入
     */
    function _validateBatchInput(address token, uint256 recipientCount) internal view {
        require(token != address(0), "Invalid token address");
        require(recipientCount > 0, "No recipients");
        require(recipientCount <= batchLimit, "Batch too large");
    }

    /**
     * @dev 内部函数：检查授权和余额
     */
    function _checkAllowanceAndBalance(IERC20Upgradeable tokenContract, uint256 amount) internal view {
        require(
            tokenContract.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );
        require(
            tokenContract.balanceOf(msg.sender) >= amount,
            "Insufficient balance"
        );
    }

    /**
     * @dev 内部函数：更新统计信息
     */
    function _updateStatistics(address user, address token, uint256 amount, uint256 count) internal {
        userTotalTransferred[user] += amount;
        userTokenTransferred[user][token] += amount;
        totalTransactions += count;
        totalVolume += amount;
    }

    /**
     * @dev 内部函数：更新用户统计
     */
    function _updateUserStatistics(address user, address token, uint256 amount) internal {
        userTotalTransferred[user] += amount;
        userTokenTransferred[user][token] += amount;
    }

    // ========== 管理功能 ==========

    /**
     * @dev 更新批量限制
     */
    function updateBatchLimit(uint256 newLimit) external onlyOwner {
        require(newLimit > 0 && newLimit <= 1000, "Invalid batch limit");
        batchLimit = newLimit;
        emit BatchLimitUpdated(newLimit);
    }

    /**
     * @dev 紧急停止合约
     */
    function emergencyStop() external onlyOwner {
        stopped = true;
        emit EmergencyStop(true);
    }

    /**
     * @dev 恢复合约运行
     */
    function resume() external onlyOwner {
        stopped = false;
        emit EmergencyStop(false);
    }

    /**
     * @dev 提取误转入的ERC20代币
     */
    function sweepToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        
        IERC20Upgradeable tokenContract = IERC20Upgradeable(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No balance to sweep");

        require(
            tokenContract.transfer(owner(), balance),
            "Sweep failed"
        );

        emit TokenSwept(token, owner(), balance);
    }

    // ========== 视图函数 ==========


    /**
     * @dev 获取用户统计信息
     */
    function getUserStats(address user) external view returns (
        uint256 totalTransferred,
        uint256 uniqueTokensCount
    ) {
        // 注意：这里需要实际实现唯一代币计数
        return (userTotalTransferred[user], 0);
    }

    /**
     * @dev 获取当前实现合约地址
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    // ========== 修饰器 ==========

    modifier whenNotStopped() {
        require(!stopped, "Contract is stopped");
        _;
    }

    // 接收ETH（防止误转）
    receive() external payable {
        revert("Direct ETH transfers not allowed");
    }

    fallback() external payable {
        revert("Invalid function call");
    }
}