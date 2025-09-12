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

contract PIJS_USDT is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    // 保存每个账户的代币余额
    mapping(address => uint256) private _balances;
    // 授权转账额度
    mapping(address => mapping(address => uint256)) private _allowances;
    // 总发行量
    uint256 private _totalSupply;

    string private _name = "USDT Token";
    string private _symbol = "USDT";
    // 交易对地址（如Uniswap中创建的Pair地址）
    mapping(address => bool) public pairs;
    // 免手续费白名单地址
    mapping(address => bool) public excludeFee;
    mapping(address => uint) public purchaseAmount;
    // 	每个地址的交易额度上限
    mapping(address => uint) public purchaseAmountLimits;
    // 是否允许非白名单用户交易
    bool public tradeToPublic;
    // 节点奖励手续费（千分比）
    uint public nodeDistributeFee = 10;
    // 销毁手续费（千分比）
    uint public burnFee = 5;
    // 运维地址手续费（千分比）
    uint public operationFee = 5;
    address public nodeDistributePool;
    address public operationAdd;

    constructor(
        address _receiver,
        address _WPIJS,
        IUniswapV2Router02 _iUniswapV2Router02,
        address _nodeDistributePool,
        address _operationAdd
    ) {
        nodeDistributePool = _nodeDistributePool;
        operationAdd = _operationAdd;
        IUniswapV2Factory iUniswapV2Factory = IUniswapV2Factory(
            _iUniswapV2Router02.factory()
        );
        // token1 = PIJS_USDT , token2 = WPIJS
        address pair1 = iUniswapV2Factory.createPair(address(this), _WPIJS);
        pairs[pair1] = true;

        excludeFee[_receiver] = true;

        _mint(_receiver, 3_000_000 * 10 ** decimals());
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function setPair(address _pair, bool _state) public onlyOwner {
        require(_pair != address(0), "PIJS_USDT:ZERO_ADDRESS");
        pairs[_pair] = _state;
    }

    function setExcludeFee(address _address, bool _state) public onlyOwner {
        require(_address != address(0), "PIJS_USDT:ZERO_ADDRESS");
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

    function batchSetPurchaseAmountLimit(
        address[] calldata accounts,
        uint[] calldata limits
    ) public onlyOwner {
        require(accounts.length == limits.length, "length error");
        for (uint i = 0; i < accounts.length; i++) {
            purchaseAmountLimits[accounts[i]] = limits[i];
        }
    }

    function setTraseToPublic(bool _tradeToPublic) public onlyOwner {
        tradeToPublic = _tradeToPublic;
    }

    function setFee(
        uint _nodeDistributeFee,
        uint _burnFee,
        uint _operationFee
    ) public onlyOwner {
        nodeDistributeFee = _nodeDistributeFee;
        burnFee = _burnFee;
        operationFee = _operationFee;
    }

    function setNodeDistributePool(
        address _nodeDistributePool
    ) public onlyOwner {
        nodeDistributePool = _nodeDistributePool;
    }

    function setOperationAdd(address _operationAdd) public onlyOwner {
        operationAdd = _operationAdd;
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
        bool isSwap = pairs[from] || pairs[to];
        if (isSwap) {
            if (excludeFee[from] || excludeFee[to]) {
                // whiteList
                _standardTransfer(from, to, amount);
            } else {
                _swapTransfer(from, to, amount);
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
        if (pairs[to] && !tradeToPublic) {
            require(
                purchaseAmountLimits[from] > 0,
                "PIJS: not allowed to trade"
            );
            require(
                (purchaseAmount[from] + amount) <= purchaseAmountLimits[from],
                "PIJS: exceed limit"
            );
            purchaseAmount[from] += amount;
        }
        uint nodeDistributeAmount = (amount * nodeDistributeFee) / 1000;
        _balances[from] -= nodeDistributeAmount;
        _balances[nodeDistributePool] += nodeDistributeAmount;
        emit Transfer(from, nodeDistributePool, nodeDistributeAmount);

        uint burnAmount = (amount * burnFee) / 1000;
        _burn(from, burnAmount);

        uint operationAmount = (amount * operationFee) / 1000;
        _balances[from] -= operationAmount;
        _balances[operationAdd] += operationAmount;
        emit Transfer(from, operationAdd, operationAmount);

        uint tAmount = amount -
            nodeDistributeAmount -
            burnAmount -
            operationAmount;
        _balances[from] -= tAmount;
        _balances[to] += tAmount;
        emit Transfer(from, to, tAmount);
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
}
