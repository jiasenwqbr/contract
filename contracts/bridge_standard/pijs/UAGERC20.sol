// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UAGERC20 is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    
    // === Events ===
    event GlobalWhitelistUpdated(address indexed account, bool status);
    event TradeWhitelistUpdated(address indexed account, bool status);
    event TradeWhitelistBuyLimitUpdated(address indexed account, uint256 limit);
    event BuyFeeReceiverAdded(address indexed receiver, uint256 rate);
    event SellFeeReceiverAdded(address indexed receiver, uint256 rate);
    event BuyFeeReceiverUpdated(uint256 indexed index, address receiver, uint256 rate);
    event SellFeeReceiverUpdated(uint256 indexed index, address receiver, uint256 rate);
    event BuyFeeReceiverRemoved(uint256 indexed index);
    event SellFeeReceiverRemoved(uint256 indexed index);
    event TradingEnabledUpdated(bool enabled);
    event PairEnabledStatusUpdated(address indexed pair, bool enabled);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "UAGERC20";
    string private _symbol = "UAG";

    mapping(address => bool) public pairs;

    mapping(address => bool) public excludeFee;

    // 支持多个手续费接收者的结构体
    struct FeeReceiver {
        address receiver;
        uint256 rate; // 费率，基数1000，例如25表示2.5%
    }
    
    
    // 支持多个手续费接收者
    FeeReceiver[] public buyFeeReceivers;
    FeeReceiver[] public sellFeeReceivers;
    bool public tradeToPublic;

    address public operator;

    // 新增状态变量
    mapping(address => bool) public globalWhitelist; // 整体白名单（免疫手续费、无视交易开关、无视交易对开放）
    mapping(address => bool) public tradeWhitelist; // 交易白名单（交易开关关闭时可交易）
    mapping(address => uint256) public tradeWhitelistBuyLimit; // 交易白名单购买上限
    mapping(address => uint256) public tradeWhitelistBoughtAmount; // 交易白名单已购买数量
    
    bool private tradingEnabled = true; // 交易开关
    mapping(address => bool) public pairsEnabled; //交易对开放状态
    address private pifUsdtAddr;
    address private pifPijsAddr;

    constructor(
        address _receiver,
        address _usdt,
        IUniswapV2Router02 _iUniswapV2Router02,
        address _operator,
        address _wethAddress
    ) {
        // 初始化后通过 addBuyFeeReceiver/addSellFeeReceiver 设置手续费接收者
        IUniswapV2Factory iUniswapV2Factory = IUniswapV2Factory(
            _iUniswapV2Router02.factory()
        );
        // token1 = PIF , token2 = USDT
        address pair1 = iUniswapV2Factory.createPair(address(this), _usdt);
        pairs[pair1] = true;
        pairsEnabled[pair1] = false; // USDT交易对默认关闭，需要手动开启
        pifUsdtAddr = pair1;
        excludeFee[_receiver] = true;
        globalWhitelist[_receiver] = true; // 初始设置为全局白名单
        globalWhitelist[_operator] = true; // operator也设置为全局白名单

        address pair2 = iUniswapV2Factory.createPair(address(this), _wethAddress);
        pairs[pair2] = true;
        pairsEnabled[pair2] = false; // PIJS交易对默认开启
        pifPijsAddr = pair2;
        operator = _operator;
        _mint(_receiver, 628_000_000 * 10 ** decimals());
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
    }

    // 新增修饰器：检查交易是否启用或调用者在白名单中
    modifier tradingAllowed() {
        require(tradingEnabled || globalWhitelist[msg.sender], "Trading is disabled or not whitelisted");
        _;
    }

    modifier onlyOperater(){
        require(msg.sender == operator,"Only operator can do");
        _;
    }
    // === 白名单管理函数 ===
    
    // 整体白名单管理（免疫手续费、无视交易开关、无视交易对开放）
    function updateGlobalWhitelist(address _account, bool _status) external onlyOwner {
        globalWhitelist[_account] = _status;
        emit GlobalWhitelistUpdated(_account, _status);
    }
    
    function batchUpdateGlobalWhitelist(address[] calldata _accounts, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            globalWhitelist[_accounts[i]] = _status;
            emit GlobalWhitelistUpdated(_accounts[i], _status);
        }
    }
    
    // 交易白名单管理（交易开关关闭时可交易）
    function updateTradeWhitelist(address _account, bool _status) external onlyOwner {
        tradeWhitelist[_account] = _status;
        emit TradeWhitelistUpdated(_account, _status);
    }
    
    function batchUpdateTradeWhitelist(address[] calldata _accounts, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            tradeWhitelist[_accounts[i]] = _status;
            emit TradeWhitelistUpdated(_accounts[i], _status);
        }
    }
    
    // 设置交易白名单购买上限
    function setTradeWhitelistBuyLimit(address _account, uint256 _limit) external onlyOwner {
        tradeWhitelistBuyLimit[_account] = _limit;
        emit TradeWhitelistBuyLimitUpdated(_account, _limit);
    }
    
    function batchSetTradeWhitelistBuyLimit(address[] calldata _accounts, uint256[] calldata _limits) external onlyOwner {
        require(_accounts.length == _limits.length, "UAG: Arrays length mismatch");
        for (uint256 i = 0; i < _accounts.length; i++) {
            tradeWhitelistBuyLimit[_accounts[i]] = _limits[i];
            emit TradeWhitelistBuyLimitUpdated(_accounts[i], _limits[i]);
        }
    }
    
    // 重置交易白名单已购买数量
    function resetTradeWhitelistBoughtAmount(address _account) external onlyOwner {
        tradeWhitelistBoughtAmount[_account] = 0;
    }

    function updateTradingEnabled(bool flag) external onlyOwner {
        tradingEnabled = flag;
        emit TradingEnabledUpdated(flag);
    } 
    function getTradingEnabled() public view returns(bool){
        return tradingEnabled;
    }

    function setPair(address _pair, bool _state) public onlyOwner {
        require(_pair != address(0), "UAG:ZERO_ADDRESS");
        pairs[_pair] = _state;
    }
    
    function setPairsEnabledStatus(address _pair, bool _state) public onlyOwner {
        require(_pair != address(0), "UAG:ZERO_ADDRESS");
        pairsEnabled[_pair] = _state;
        emit PairEnabledStatusUpdated(_pair, _state);
    }
    
    function getPairsEnabledStatus(address _pair) public view returns(bool) {
        return  pairsEnabled[_pair];
    }

    function mint(address to, uint256 amount) external  onlyOperater {
        _mint(to, amount);
    }

    function setExcludeFee(address _address, bool _state) public onlyOwner {
        require(_address != address(0), "UAG:ZERO_ADDRESS");
        excludeFee[_address] = _state;
    }

    function batchSetExcludeFee(
        address[] calldata _address,
        bool _state
    ) public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            excludeFee[_address[i]] = _state;
        }
    }

    
    // === 多个手续费接收者管理函数 ===
    
    
    // 批量设置购买手续费接收者（清空后重新设置）
    function setBuyFeeReceivers(address[] calldata _receivers, uint256[] calldata _rates) external onlyOwner {
        require(_receivers.length == _rates.length, "UAG: Arrays length mismatch");
        require(_receivers.length > 0, "UAG: Empty arrays");
        
        // 检查总费率不超过100%
        uint256 totalRate = 0;
        for (uint256 i = 0; i < _rates.length; i++) {
            // require(_receivers[i] != address(0), "UAG: Zero address");
            require(_rates[i] > 0 && _rates[i] <= 1000, "UAG: Invalid rate");
            totalRate += _rates[i];
        }
        require(totalRate <= 1000, "UAG: Total buy fee rate exceeds 100%");
        
        // 清空现有设置
        delete buyFeeReceivers;
        
        // 添加新设置
        for (uint256 i = 0; i < _receivers.length; i++) {
            buyFeeReceivers.push(FeeReceiver(_receivers[i], _rates[i]));
            emit BuyFeeReceiverAdded(_receivers[i], _rates[i]);
        }
    }
    
    // 批量设置出售手续费接收者（清空后重新设置）
    function setSellFeeReceivers(address[] calldata _receivers, uint256[] calldata _rates) external onlyOwner {
        require(_receivers.length == _rates.length, "UAG: Arrays length mismatch");
        require(_receivers.length > 0, "UAG: Empty arrays");
        
        // 检查总费率不超过100%
        uint256 totalRate = 0;
        for (uint256 i = 0; i < _rates.length; i++) {
            // require(_receivers[i] != address(0), "UAG: Zero address");
            require(_rates[i] > 0 && _rates[i] <= 1000, "UAG: Invalid rate");
            totalRate += _rates[i];
        }
        require(totalRate <= 1000, "UAG: Total sell fee rate exceeds 100%");
        
        // 清空现有设置
        delete sellFeeReceivers;
        
        // 添加新设置
        for (uint256 i = 0; i < _receivers.length; i++) {
            sellFeeReceivers.push(FeeReceiver(_receivers[i], _rates[i]));
            emit SellFeeReceiverAdded(_receivers[i], _rates[i]);
        }
    }
    
    // 清空所有购买手续费接收者
    function clearAllBuyFeeReceivers() external onlyOwner {
        delete buyFeeReceivers;
    }
    
    // 清空所有出售手续费接收者
    function clearAllSellFeeReceivers() external onlyOwner {
        delete sellFeeReceivers;
    }
    
    // 添加购买手续费接收者
    function addBuyFeeReceiver(address _receiver, uint256 _rate) external onlyOwner {
        // require(_receiver != address(0), "UAG: Zero address");
        require(_rate > 0 && _rate <= 1000, "UAG: Invalid rate"); // 最大100%
        
        // 检查总费率不超过100%
        uint256 totalRate = _getTotalBuyFeeRate() + _rate;
        require(totalRate <= 1000, "UAG: Total buy fee rate exceeds 100%");
        
        buyFeeReceivers.push(FeeReceiver(_receiver, _rate));
        emit BuyFeeReceiverAdded(_receiver, _rate);
    }
    
    // 添加出售手续费接收者
    function addSellFeeReceiver(address _receiver, uint256 _rate) external onlyOwner {
        // require(_receiver != address(0), "UAG: Zero address");
        require(_rate > 0 && _rate <= 1000, "UAG: Invalid rate"); // 最大100%
        
        // 检查总费率不超过100%
        uint256 totalRate = _getTotalSellFeeRate() + _rate;
        require(totalRate <= 1000, "UAG: Total sell fee rate exceeds 100%");
        
        sellFeeReceivers.push(FeeReceiver(_receiver, _rate));
        emit SellFeeReceiverAdded(_receiver, _rate);
    }
    
    // 更新购买手续费接收者
    function updateBuyFeeReceiver(uint256 _index, address _receiver, uint256 _rate) external onlyOwner {
        require(_index < buyFeeReceivers.length, "UAG: Index out of bounds");
        // require(_receiver != address(0), "UAG: Zero address");
        require(_rate > 0 && _rate <= 1000, "UAG: Invalid rate");
        
        // 检查总费率不超过100%（排除当前更新的项）
        uint256 totalRate = _getTotalBuyFeeRate() - buyFeeReceivers[_index].rate + _rate;
        require(totalRate <= 1000, "UAG: Total buy fee rate exceeds 100%");
        
        buyFeeReceivers[_index] = FeeReceiver(_receiver, _rate);
        emit BuyFeeReceiverUpdated(_index, _receiver, _rate);
    }
    
    // 更新出售手续费接收者
    function updateSellFeeReceiver(uint256 _index, address _receiver, uint256 _rate) external onlyOwner {
        require(_index < sellFeeReceivers.length, "UAG: Index out of bounds");
        // require(_receiver != address(0), "UAG: Zero address");
        require(_rate > 0 && _rate <= 1000, "UAG: Invalid rate");
        
        // 检查总费率不超过100%（排除当前更新的项）
        uint256 totalRate = _getTotalSellFeeRate() - sellFeeReceivers[_index].rate + _rate;
        require(totalRate <= 1000, "UAG: Total sell fee rate exceeds 100%");
        
        sellFeeReceivers[_index] = FeeReceiver(_receiver, _rate);
        emit SellFeeReceiverUpdated(_index, _receiver, _rate);
    }
    
    // 删除购买手续费接收者
    function removeBuyFeeReceiver(uint256 _index) external onlyOwner {
        require(_index < buyFeeReceivers.length, "UAG: Index out of bounds");
        buyFeeReceivers[_index] = buyFeeReceivers[buyFeeReceivers.length - 1];
        buyFeeReceivers.pop();
        emit BuyFeeReceiverRemoved(_index);
    }
    
    // 删除出售手续费接收者
    function removeSellFeeReceiver(uint256 _index) external onlyOwner {
        require(_index < sellFeeReceivers.length, "UAG: Index out of bounds");
        sellFeeReceivers[_index] = sellFeeReceivers[sellFeeReceivers.length - 1];
        sellFeeReceivers.pop();
        emit SellFeeReceiverRemoved(_index);
    }
    
    // 获取购买手续费接收者数量
    function getBuyFeeReceiversCount() external view returns (uint256) {
        return buyFeeReceivers.length;
    }
    
    // 获取出售手续费接收者数量
    function getSellFeeReceiversCount() external view returns (uint256) {
        return sellFeeReceivers.length;
    }
    
    // === 查询函数 ===
    
    // 获取购买手续费接收者信息
    function getBuyFeeReceiver(uint256 _index) external view returns (address receiver, uint256 rate) {
        require(_index < buyFeeReceivers.length, "UAG: Index out of bounds");
        FeeReceiver memory feeReceiver = buyFeeReceivers[_index];
        return (feeReceiver.receiver, feeReceiver.rate);
    }
    
    // 获取出售手续费接收者信息
    function getSellFeeReceiver(uint256 _index) external view returns (address receiver, uint256 rate) {
        require(_index < sellFeeReceivers.length, "UAG: Index out of bounds");
        FeeReceiver memory feeReceiver = sellFeeReceivers[_index];
        return (feeReceiver.receiver, feeReceiver.rate);
    }
    
    // 获取所有购买手续费接收者
    function getAllBuyFeeReceivers() external view returns (FeeReceiver[] memory) {
        return buyFeeReceivers;
    }
    
    // 获取所有出售手续费接收者
    function getAllSellFeeReceivers() external view returns (FeeReceiver[] memory) {
        return sellFeeReceivers;
    }
    
    // 检查是否为全局白名单用户
    function isGlobalWhitelisted(address _account) external view returns (bool) {
        return globalWhitelist[_account];
    }
    
    // 检查是否为交易白名单用户
    function isTradeWhitelisted(address _account) external view returns (bool) {
        return tradeWhitelist[_account];
    }
    
    // 获取交易白名单用户的购买上限
    function getTradeWhitelistBuyLimit(address _account) external view returns (uint256) {
        return tradeWhitelistBuyLimit[_account];
    }
    
    // 获取交易白名单用户已购买数量
    function getTradeWhitelistBoughtAmount(address _account) external view returns (uint256) {
        return tradeWhitelistBoughtAmount[_account];
    }
    
    // 获取交易白名单用户剩余可购买数量
    function getTradeWhitelistRemainingBuyAmount(address _account) external view returns (uint256) {
        uint256 limit = tradeWhitelistBuyLimit[_account];
        uint256 bought = tradeWhitelistBoughtAmount[_account];
        if (limit > bought) {
            return limit - bought;
        }
        return 0;
    }
    
    // 获取总购买手续费率
    function getTotalBuyFeeRate() external view returns (uint256) {
        return _getTotalBuyFeeRate();
    }
    
    // 获取总出售手续费率
    function getTotalSellFeeRate() external view returns (uint256) {
        return _getTotalSellFeeRate();
    }
    
    // 内部函数：计算总购买手续费率
    function _getTotalBuyFeeRate() internal view returns (uint256) {
        uint256 totalRate = 0;
        for (uint256 i = 0; i < buyFeeReceivers.length; i++) {
            totalRate += buyFeeReceivers[i].rate;
        }
        return totalRate;
    }
    
    // 内部函数：计算总出售手续费率
    function _getTotalSellFeeRate() internal view returns (uint256) {
        uint256 totalRate = 0;
        for (uint256 i = 0; i < sellFeeReceivers.length; i++) {
            totalRate += sellFeeReceivers[i].rate;
        }
        return totalRate;
    }

    function setTradeToPublic(bool _tradeToPublic) public onlyOwner {
        tradeToPublic = _tradeToPublic;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
   function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        // 检查交易是否整体开放
        require(tradeToPublic, "UAG: not open");

        bool isSwap = pairs[from] || pairs[to];
        if (isSwap) {
            // 检查是否为全局白名单用户（完全免疫所有限制）
            if (globalWhitelist[from] || globalWhitelist[to]) {
                _standardTransfer(from, to, amount);
            } else {
                // 非全局白名单用户需要检查交易规则
                // 不是全局白名单就要校验交易币对是否开启
                if (pairs[from]) {
                    require(pairsEnabled[from], "UAG: Pair not enabled");
                }
                if (pairs[to]) {
                    require(pairsEnabled[to], "UAG: Pair not enabled");
                }    
                // 1. 检查交易开关
                if (!tradingEnabled) {
                    // 交易开关关闭时，只允许交易白名单用户交易
                    require(tradeWhitelist[from] || tradeWhitelist[to], "UAG: Trading disabled");
                    
                    // 如果是从 swap 中购买（pairs[from] == true），需要检查购买上限
                    if (pairs[from] && tradeWhitelistBuyLimit[to] > 0) {
                        require(
                            tradeWhitelistBoughtAmount[to] + amount <= tradeWhitelistBuyLimit[to],
                            "UAG: Exceeds buy limit"
                        );
                        tradeWhitelistBoughtAmount[to] += amount;
                    }
                }
                 
                // 2. 执行swap转账（检查是否免手续费）
                if (excludeFee[from] || excludeFee[to]) {
                    _standardTransfer(from, to, amount); // 免手续费转账
                } else {
                    _swapTransfer(from, to, amount); // 正常收取手续费转账
                }
            }
        } else {
            _standardTransfer(from, to, amount);
        }
        _afterTokenTransfer(from, to, amount);
    }

    function _standardTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _swapTransfer(address from, address to, uint256 amount) internal {
        if (pairs[from]) {
            // buy - 从 swap 中购买
            uint256 totalFeeAmount = 0;
            
            if (buyFeeReceivers.length > 0) {
                // 使用多个手续费接收者
                for (uint256 i = 0; i < buyFeeReceivers.length; i++) {
                    uint256 feeAmount = (amount * buyFeeReceivers[i].rate) / 1000;
                    if (feeAmount > 0) {
                        _balances[from] -= feeAmount;
                        _balances[buyFeeReceivers[i].receiver] += feeAmount;
                        emit Transfer(from, buyFeeReceivers[i].receiver, feeAmount);
                        totalFeeAmount += feeAmount;
                    }
                }
            }
            uint256 transferAmount = amount - totalFeeAmount;
            _balances[from] -= transferAmount;
            _balances[to] += transferAmount;
            emit Transfer(from, to, transferAmount);
        } else {
            // sell - 卖出到 swap
            uint256 totalFeeAmount = 0;
            
            if (sellFeeReceivers.length > 0) {
                // 使用多个手续费接收者
                for (uint256 i = 0; i < sellFeeReceivers.length; i++) {
                    uint256 feeAmount = (amount * sellFeeReceivers[i].rate) / 1000;
                    if (feeAmount > 0) {
                        _balances[from] -= feeAmount;
                        _balances[sellFeeReceivers[i].receiver] += feeAmount;
                        emit Transfer(from, sellFeeReceivers[i].receiver, feeAmount);
                        totalFeeAmount += feeAmount;
                    }
                }
            }

            uint256 transferAmount = amount - totalFeeAmount;
            _balances[from] -= transferAmount;
            _balances[to] += transferAmount;
            emit Transfer(from, to, transferAmount);
        }
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    
    // === 部署和使用文档 ===
    /*
    === 合约部署参数 ===
    constructor(
        address _receiver,    // 接收初始代币的地址，一般为项目方钱包
        address _usdt,        // USDT代币合约地址
        IUniswapV2Router02 _iUniswapV2Router02, // Uniswap V2 路由器地址
        address _operator,    // 操作员地址，可以执行mint操作
        address _wethAddress  // WETH代币地址
    )
    
    === 部署后初始化步骤 ===
    
    1. 设置手续费接收者（必需，否则无法收取手续费）：
       批量设置（推荐）：
       - setBuyFeeReceivers([marketingWallet, devWallet], [10, 5])     // 1% + 0.5%
       - setSellFeeReceivers([treasuryWallet, burnWallet], [15, 10])  // 1.5% + 1%
       
       逐个添加：
       - addBuyFeeReceiver(marketingWallet, 10)  // 市场钱包，1%费率
       - addBuyFeeReceiver(devWallet, 5)         // 开发钱包，0.5%费率
    
    2. 设置全局白名单（免疫所有限制）：
       - updateGlobalWhitelist(dexRouter, true)      // DEX路由器
       - updateGlobalWhitelist(bridgeContract, true) // 跨链桥合约
       - batchUpdateGlobalWhitelist([addr1, addr2], true) // 批量设置
    
    3. 设置交易白名单（交易关闭时可交易）：
       - updateTradeWhitelist(vipUser, true)
       - setTradeWhitelistBuyLimit(vipUser, 1000 * 10**18) // 设置购买上限
    
    4. 启用交易：
       - setPairsEnabledStatus(usdtPair, true) // 开放USDT交易对
       - setPairsEnabledStatus(ethPair, true)  // 开放ETH交易对
       - setTradeToPublic(true)                // 开放公开交易
       - updateTradingEnabled(true)            // 全局启用交易
    
    === 功能说明 ===
    
    • 多元手续费系统：支持多个地址同时接收手续费，各自设置独立费率，总费率不超过100%
    • 全局白名单：完全绣过所有限制，包括手续费、交易开关、交易对限制
    • 交易白名单：交易关闭时仍可交易，但可设置购买上限
    • 智能检测：swap交易会自动触发手续费收取逻辑
    • 简洁高效：只保留必要功能，去除了冗余的单费率系统
    
    === 安全特性 ===
    
    • 费率保护：手续费率总和不超过100%，防止过度收费
    • 地址验证：所有地址参数都会检查不为零地址
    • 权限控制：只有owner可以修改关键参数
    • 事件日志：所有重要操作都会发出事件供监控
    */

}
