// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
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
interface MintableERC20 {
     function mint(address to, uint256 amount) external;
     function burnFrom(address account, uint256 amount) external;
}
contract BridgeTarget is
    Initializable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable{
    using SafeMath for uint;
    // 拥有合约升级、参数配置权限。
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    // 可调用 withdraw()、执行出金操作。
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");

    uint256 public constant FEE_DENOMINATOR = 1000; // 精度：1000
    uint256 public feePercent;      // 手续费，例如 30 表示 3%
    address public feeReceiver;     // 手续费接收地址
    // 签名者地址
    address public signer;
    // EIP‑712 签名域（domain）哈希，用于防重放攻击。
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 private constant  PERMIT_MINT_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(address caller,address to,uint256 amount,address token,uint256 orderId)"
        )
    );

    bytes32 private constant PERMIT_BURN_TYPEHASH = keccak256(
        abi.encodePacked("Permit(address caller,uint256 amount,address token,uint256 orderId)")
    );
    mapping(uint256 => MintTokenData) public mintTokenOrders;
    mapping(address => uint256[]) public tokenMintIds;
    mapping(address => uint256) public tokenMintAmount;

    mapping(uint256 => BurnTokenData) public burnTokenOrders;
    mapping(address => uint256[]) public tokenBurnIds;
    mapping(address => uint256) public tokenBurnAmount;
    /////////////////////////////////////////////   Event
    event FeeUpdated(uint256 newFee);
    event FeeReceiverUpdated(address newReceiver);
    event MintToken(address caller,address token,address  to, uint256 amount, uint256 fee, uint256 orderId);
    event TokenBurned(address  from, address token,uint256 amount, uint256 orderId);


    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(MANAGE_ROLE) {}

    function initialize(
        address operator,
        address _feeReceiver,
        uint256 _feePercent,
        address _signer
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init(); 

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATE_ROLE, operator);
        _grantRole(MANAGE_ROLE, msg.sender);

        feePercent = _feePercent;
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
                keccak256(bytes("BridgeTarget")),
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

    //////////////////////////////////   mintERC20
    struct MintTokenData {
        address caller;
        address to;
        uint256 amount;
        address token;
        uint256 orderId;
    }

    /// @notice 由 OPERATOR 在收到原链锁定后调用，给用户 mint
    function mintToken(bytes calldata data) external whenNotPaused nonReentrant onlyRole(OPERATE_ROLE) {
        
        MintTokenData memory mintTokenData = parseMintTokenData(data);
        require(mintTokenOrders[mintTokenData.orderId].orderId == 0,"BridgeTarget:The order has minted");
        uint256 feeAmount = (mintTokenData.amount * feePercent) / FEE_DENOMINATOR;
        uint256 userAmount = mintTokenData.amount - feeAmount;
        mintTokenOrders[mintTokenData.orderId] = mintTokenData;
        tokenMintIds[mintTokenData.token].push(mintTokenData.orderId);
        tokenMintAmount[mintTokenData.token] = tokenMintAmount[mintTokenData.token].add(mintTokenData.amount); 
        require(mintTokenData.to != address(0), "BridgeTarget:Invalid address");
        MintableERC20(mintTokenData.token).mint(mintTokenData.to, userAmount);
        MintableERC20(mintTokenData.token).mint(feeReceiver, feeAmount);

        emit MintToken(mintTokenData.caller,mintTokenData.token,mintTokenData.to, userAmount, feeAmount, mintTokenData.orderId);
    }

    function parseMintTokenData(bytes calldata data) internal view returns (MintTokenData memory) {
        (
            address caller,
            address to,
            uint256 amount,
            address token,
            uint256 orderId,
            bytes memory signature
        ) =  abi.decode(
            data,
            (
                address,
                address,
                uint256,
                address,
                uint256,
                bytes
            )
        );
        require(caller == msg.sender, "BridgeTarget: INVALID_USER");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

         bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_MINT_TYPEHASH,
                        caller,
                        to,
                        amount,
                        token,
                        orderId
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "BridgeTarget: INVALID_REQUEST"
        );
        return MintTokenData({
            caller:caller,
            to:to,
            amount:amount,
            token:token,
            orderId:orderId
        });

    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "BridgeTarget:Not Invalid Signature Data");
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

       //////////////////////////// burnForCrossChain
    struct BurnTokenData {
        address caller;
        uint256 amount;
        address token;
        uint256 orderId;
    }

    /// @notice 用户 burn 表示要跨回原链
    function tokenBurned(bytes calldata data) external whenNotPaused nonReentrant {
        BurnTokenData memory burnTokenData = parseBurnTokenData(data);
        require(burnTokenOrders[burnTokenData.orderId].orderId == 0,"BridgeTarget:The order has burned");
        require(burnTokenData.amount>0,"BridgeTarget:amount should not be zero");
        MintableERC20(burnTokenData.token).burnFrom(msg.sender, burnTokenData.amount);

        burnTokenOrders[burnTokenData.orderId] = burnTokenData;
        tokenBurnIds[burnTokenData.token].push(burnTokenData.orderId);
        tokenBurnAmount[burnTokenData.token] = tokenBurnAmount[burnTokenData.token] + burnTokenData.amount;

        emit TokenBurned(msg.sender,burnTokenData.token, burnTokenData.amount, burnTokenData.orderId);
    }

    function parseBurnTokenData(bytes calldata data) internal view returns (BurnTokenData memory) {
        (
            address caller,
            uint256 amount,
            address token,
            uint256 orderId,
            bytes memory signature
        ) =  abi.decode(
            data,
            (
                address,
                uint256,
                address,
                uint256,
                bytes
            )
        );
        require(caller == msg.sender, "BridgeTarget: INVALID_USER");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

         bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_BURN_TYPEHASH,
                        caller,
                        amount,
                        token,
                        orderId
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "BridgeTarget: INVALID_REQUEST"
        );

        return BurnTokenData({
            caller:caller,
            amount:amount,
            token:token,
            orderId:orderId
        });
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


    ////////////////////////////////////////////////  setter getter
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






}