// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../utils/SafeMath.sol";
contract UACERC20 is
    Initializable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;
    // 拥有合约升级、参数配置权限。
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    // 可调用 withdraw()、执行出金操作。
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");

    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE"); // 白名单角色

    uint256 public constant FEE_DENOMINATOR = 10000; // 精度：10000表示万分比
    uint256 public feePercent;      // 万分比手续费，例如 30 表示 0.3%
    address public feeReceiver;     // 手续费接收地址
    // 签名者地址
    address public signer;
    // EIP‑712 签名域（domain）哈希，用于防重放攻击。
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 private constant  PERMIT_MINT_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(address caller,address withdrawContract,uint256 amount,uint256 fee,uint256 orderId,uint256 chainId)"
        )
    );

    mapping(address => bool) private whiteList;  // 手续费白名单
    mapping(uint24 => uint24) public  feeAmountTick; // 不同类型的手续费


    event FeeUpdated(uint256 newFee);
    event FeeReceiverUpdated(address newReceiver);
    event MintToken(address caller,uint256 amount, uint256 fee, address withdrawContract,uint256 orderId);
   
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(MANAGE_ROLE) {}

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address operator,
        address _feeReceiver,
        uint24 _feePercent,
        address _signer
    ) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init(); 

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATE_ROLE, operator);
        _grantRole(MANAGE_ROLE, admin);
        _grantRole(WHITELIST_ROLE, admin);

        // feePercent = _feePercent;
        feeAmountTick[1] = _feePercent;
        feeReceiver = _feeReceiver;
        signer = _signer;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("PIJSBridgeTarget")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    // 修改修饰器逻辑：暂停时仅允许白名单
    modifier whenNotPausedOrWhitelisted() {
        require(
            !paused() || hasRole(WHITELIST_ROLE, msg.sender),
            "Contract is paused and caller is not whitelisted"
        );
        _;
    }

    /// @notice 管理员设置手续费
    function setFeePercent(uint256 _feePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feePercent <= 1500, "Fee too high"); // 最多 15%
        feePercent = _feePercent;
        emit FeeUpdated(_feePercent);
    }

    function setFeeReceiver(address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeReceiver = _receiver;
        emit FeeReceiverUpdated(_receiver); 
    }
    function setSigner(address _signer) public onlyRole(MANAGE_ROLE) {
        signer = _signer;
    }

     // add to blacklist
    function setAddressToWhiteList(address _address) external onlyRole(OPERATE_ROLE) {
        whiteList[_address] = true;
    }

    // remove from blacklist
    function removeFromBlackList(address _address) external  onlyRole(OPERATE_ROLE) {
        require(isWhiteListed(_address),"Address not in white list");
        whiteList[_address] = false;
    }
    // 检查地址是否在白名单中
    function isWhiteListed(address _address) public view returns (bool) {
        return  whiteList[_address];
    }

    function setFeeAmountTick(uint24 fee_type,uint24 fee_amount) external onlyRole(OPERATE_ROLE) {
        feeAmountTick[fee_type] = fee_amount;
    }
    function getFeeAmountTick(uint24 fee_type) public view  returns (uint24) {
        if (feeAmountTick[fee_type] == 0){
            return feeAmountTick[1];
        }
        return feeAmountTick[fee_type];
    }

    //////////////////////////////////   mintUAC
    struct MintTokenData {
        address caller;
        address withdrawContract;
        uint256 amount;
        uint256 fee;
        uint256 orderId;
        uint256 chainId;
    }
    function mint(address to, uint256 amount) external whenNotPausedOrWhitelisted nonReentrant onlyRole(OPERATE_ROLE) {
        _mint(to, amount);
    }

    /// @notice 由 OPERATOR 在收到原链锁定后调用，给用户 mint
    function mintToken(bytes calldata data) external whenNotPausedOrWhitelisted nonReentrant onlyRole(OPERATE_ROLE) {
        
        MintTokenData memory mintTokenData = parseMintTokenData(data);
        require(feeReceiver != address(0), "UnionBridgeSource: Invalid fee receiver");
        require(mintTokenData.fee <= mintTokenData.amount, "UnionBridgeSource: Fee exceeds amount");
        require(mintTokenData.amount > 0, "UnionBridgeSource: Amount must be positive");
        // 计算用户实际应得金额
        uint256 userAmount = mintTokenData.amount.sub(mintTokenData.fee);
        require(mintTokenData.withdrawContract != address(0), "Invalid address");
        _mint(feeReceiver, mintTokenData.fee); // 收手续费
        _mint(mintTokenData.withdrawContract, userAmount); // 将用户的mint至withdrawContract合约

        emit MintToken(mintTokenData.caller,mintTokenData.amount, mintTokenData.fee,mintTokenData.withdrawContract, mintTokenData.orderId);
    }

    function parseMintTokenData(bytes calldata data) internal view returns (MintTokenData memory) {
        (
            address caller,
            address withdrawContract,
            uint256 amount,
            uint256 fee,
            uint256 orderId,
            uint256 chainId,
            bytes memory signature
        ) =  abi.decode(
            data,
            (
                address,
                address,
                uint256,
                uint256,
                uint256,
                uint256,
                bytes
            )
        );
        require(caller == msg.sender, "PIJSBridgeTarget: INVALID_USER");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

         bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_MINT_TYPEHASH,
                        caller,
                        withdrawContract,
                        amount,
                        fee,
                        orderId,
                        chainId
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "UnionBridgeSource: INVALID_REQUEST"
        );
        return MintTokenData({
            caller:caller,
            withdrawContract:withdrawContract,
            amount:amount,
            fee:fee,
            orderId:orderId,
            chainId:chainId
        });

    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "PIJSBridgeTarget:Not Invalid Signature Data");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // 重写 ERC20 的 transfer 方法，添加暂停/白名单逻辑
    function transfer(address to, uint256 amount) 
        public 
        override 
        whenNotPausedOrWhitelisted 
        returns (bool) 
    {
        return super.transfer(to, amount);
    }

    // 重写 ERC20 的 transferFrom 方法
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPausedOrWhitelisted returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function burnFrom(address account, uint256 amount) public override whenNotPausedOrWhitelisted nonReentrant {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}
