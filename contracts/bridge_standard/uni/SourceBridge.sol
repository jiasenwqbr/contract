// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

contract SourceBridge is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable{
    using SafeMath for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20 for IERC20;
    // 拥有合约升级、参数配置权限。
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    // 可调用 withdraw()、执行出金操作。
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    // EIP‑712 签名域（domain）哈希，用于防重放攻击。
    bytes32 public DOMAIN_SEPARATOR;
    
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}
        
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }

    // 签名者地址
    address public signer;
    // receiver：deposite() 时实际收币的地址。
    address private receiver;
    // feeReceiver：存款产生的手续费去向。 手续费接收地址
    address private feeReceiver;

    uint256 public constant FEE_DENOMINATOR = 1000; // 精度：10000表示万分比
    uint256 public feePercent;      // 万分比手续费，例如 30 表示 3%
    mapping(address => uint256) tokenFeePercentage;

    bytes32 private constant PERMIT_DEPOSIT_TYPEHASH =keccak256(
        abi.encodePacked(
            "Permit(address userAddr,address receiver,uint256 amount,uint256 orderId,uint256 chainId)"
        )
    );
    bytes32 private constant WITHDRAW_PERMIT_TYPEHASH =keccak256(
        abi.encodePacked(
            "Permit(address caller,uint256 amount,address userAddr,uint256 orderId,uint256 chainId)"
        )
    );
    bytes32 private constant PERMIT_DEPOSIT_ERC20_TYPEHASH = keccak256(
        abi.encodePacked(
             "Permit(address userAddr,address tokenAddr,address receiver,uint256 amount,uint256 orderId,uint256 chainId)"
        )
    );
    bytes32 private constant WITHDRAWERC20_PERMIT_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(address caller,address tokenAddr,uint256 amount,address userAddr,uint256 orderId,uint256 chainId)"
        )
    );

    mapping(uint256  => DepositeData) userDepositeETHOrders;
    mapping(address => uint256[]) userDepositeETHOrderIds;
    uint256 private depositeETHAmount;
    mapping(uint256 => WithDrawETHData) userWithDrawETHOrder;
    mapping(address => uint256[]) userWithDrawETHOrderIds;
    uint256 private withDrawETHAmount;
    // DepositeERC20Data
    mapping(uint256  => DepositeERC20Data) userDepositeERC20Orders;
    mapping(address => mapping(address => uint256[])) userDepositeERC20OrderIds;
    mapping(address => uint256) private depositeERC20Amount;
    mapping(uint256  => WithDrawERC20Data) userWithdrawERC20Orders;
    mapping(address => mapping(address => uint256[])) userWithdrawERC20OrderIds;
    mapping(address => uint256) private withdrawERC20Amount;

    //////////////////////////////////////////////////////// Event
    event FeeUpdated(uint256 newFee,uint256 timestamp);
    event FeeReceiverUpdated(address newReceiver,uint256 timestamp);
    event DepositeETH(address caller,uint256 amount, address receiver, uint256 order, uint256 chainId,uint256 timestamp);
    event WithDrawETH(address caller,address feeReceiver, uint256 feeAmount,address userAddr,uint256 userAmount,uint256 orderId,uint256 chainId,uint256 timestamp);
    event DepositeERC20(address caller,address tokenAddr,address receiver,uint256 amount,uint256 orderId,uint256 chainId,uint256 timestamp);
    event WithdrawERC20(address caller,address tokenAddr,address feeReceiver,uint256 feeAmount,address userAddr,uint256 userAmount,uint256 orderId,uint256 chainId,uint256 timestamp);



     function initialize(
        address _feeReceiver,
        address _signer,
        address _operator,
        uint256 _feePercent
    ) public initializer {
         __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        _grantRole(OPERATE_ROLE, _operator);
        feeReceiver = _feeReceiver;
        signer = _signer;
        feePercent = _feePercent;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SourceBridge")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }


/////////////////////////////////////////// depositeETH /////////////////////////
    struct DepositeData {
        address receiver;
        uint256 amount;
        uint256 orderId;
        uint256 chainId;
    }
    function depositeETH(bytes calldata data) external nonReentrant payable {
        require(msg.value > 0, "No ETH sent");
        DepositeData memory depositeData = parseDepositeData(data);
        require(userDepositeETHOrders[depositeData.orderId].orderId == 0,"SourceBridge:The order is exist");
        require(depositeData.amount <= msg.value,"SourceBridge:Not enough ETH");
        userDepositeETHOrders[depositeData.orderId] = depositeData;
        userDepositeETHOrderIds[msg.sender].push(depositeData.orderId);
        depositeETHAmount = depositeETHAmount + msg.value;
        emit DepositeETH(msg.sender,depositeData.amount,depositeData.receiver,depositeData.orderId,depositeData.chainId,block.timestamp);
    }

    function parseDepositeData(bytes calldata data) internal view returns (DepositeData memory) {
        (
            address userAddr,
            address _receiver,
            uint256 amount,
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
                bytes
            )
        );
        require(userAddr == msg.sender, "SourceBridge: INVALID_USER");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

         bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_DEPOSIT_TYPEHASH,
                        userAddr,
                        _receiver,
                        amount,
                        orderId,
                        chainId
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "SourceBridge: INVALID_REQUEST"
        );
        return DepositeData({
                receiver:_receiver,
                amount:amount,
                orderId:orderId,
                chainId:chainId
            });
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "SourceBridge:Not Invalid Signature Data");
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

    /////////////////////////////////////////// withdrawETH /////////////////////////
    struct WithDrawETHData {
        address caller;
        uint256 amount;
        address userAddr;
        uint256 orderId;
        uint256 chainId;
    }
    function withdrawETH(bytes calldata data) public nonReentrant onlyRole(OPERATE_ROLE) {
        WithDrawETHData memory withDrawData = parseWithDrawETHData(data);
        require(withDrawData.amount > 0,"SourceBridge:No ETH withdraw");
        require(withDrawData.amount <= address(this).balance,"SourceBridge:");
        require(userWithDrawETHOrder[withDrawData.orderId].orderId == 0,"SourceBridge: the order is withdrawed");
        // require(withDrawData.amount <= getUserDepositETH(msg.sender).sub(getUserWithDrawETH(msg.sender)) );
      
        uint256 feeAmount = (withDrawData.amount * feePercent) / FEE_DENOMINATOR;
        uint256 userAmount = withDrawData.amount - feeAmount;
        (bool sentFee, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(sentFee, "ETH transfer failed");
        (bool sendUserValue,) = payable(withDrawData.userAddr).call{value: userAmount}("");
        require(sendUserValue, "ETH transfer failed");
        userWithDrawETHOrder[withDrawData.orderId] = withDrawData;
        userWithDrawETHOrderIds[msg.sender].push(withDrawData.orderId);
        withDrawETHAmount = withDrawETHAmount + withDrawData.amount;
        emit WithDrawETH(msg.sender,feeReceiver,feeAmount,withDrawData.userAddr,userAmount,withDrawData.orderId,withDrawData.chainId,block.timestamp);
    }

    function parseWithDrawETHData(bytes calldata data) internal view returns (WithDrawETHData memory) {
        (
            address callerAddr,
            uint256 amount,
            address userAddr,
            uint256 orderId,
            uint256 chainId,
            bytes memory signature
        ) =  abi.decode(
            data,
            (
                address,
                uint256,
                address,
                uint256,
                uint256,
                bytes
            )
        );
        require(callerAddr == msg.sender, "SourceBridge: INVALID_USER");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
         bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        WITHDRAW_PERMIT_TYPEHASH,
                        callerAddr,
                        amount,
                        userAddr,
                        orderId,
                        chainId
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "SourceBridge: INVALID_REQUEST"
        );
        return WithDrawETHData({
            caller:callerAddr,
            amount:amount,
            userAddr:userAddr,
            orderId:orderId,
            chainId:chainId
        });
    }

    /////////////////////////////////////////// depositeERC20 /////////////////////////
    struct DepositeERC20Data {
        address tokenAddr;
        address receiver;
        uint256 amount;
        uint256 orderId;
        uint256 chainId;
    }
    function depositeERC20(bytes calldata data) external{
        DepositeERC20Data memory depositeERC20Data = parseDepositeERC20Data(data);
        require(userDepositeERC20Orders[depositeERC20Data.orderId].orderId == 0,"SourceBridge:The order is exist");
        require(depositeERC20Data.amount > 0, "SourceBridge:No token sent");
        IERC20(depositeERC20Data.tokenAddr).safeTransferFrom(
            msg.sender,
            address(this),
            depositeERC20Data.amount
        );
        userDepositeERC20Orders[depositeERC20Data.orderId] = depositeERC20Data;
        userDepositeERC20OrderIds[msg.sender][depositeERC20Data.tokenAddr].push(depositeERC20Data.orderId);
        depositeERC20Amount[depositeERC20Data.tokenAddr] =  depositeERC20Amount[depositeERC20Data.tokenAddr].add(depositeERC20Data.amount);

        emit DepositeERC20(msg.sender,depositeERC20Data.tokenAddr,depositeERC20Data.receiver,depositeERC20Data.amount,depositeERC20Data.orderId,depositeERC20Data.chainId,block.timestamp);
    }

    function parseDepositeERC20Data(bytes calldata data) internal view returns (DepositeERC20Data memory) {
        (
            address userAddr,
            address tokenAddr,
            address _receiver,
            uint256 amount,
            uint256 orderId,
            uint256 chainId,
            bytes memory signature
        ) =  abi.decode(
            data,
            (
                address,
                address,
                address,
                uint256,
                uint256,
                uint256,
                bytes
            )
        );
        require(userAddr == msg.sender, "SourceBridge: INVALID_USER");
         (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

         bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_DEPOSIT_ERC20_TYPEHASH,
                        userAddr,
                        tokenAddr,
                        _receiver,
                        amount,
                        orderId,
                        chainId
                    )
                )
            )
        );

        require(
            signer == ecrecover(signHash, v, r, s),
            "SourceBridge: INVALID_REQUEST"
        );
        return DepositeERC20Data({
            tokenAddr:tokenAddr,
            receiver:_receiver,
            amount:amount,
            orderId:orderId,
            chainId:chainId
        });
    }

    /////////////////////////////////////////// withdrawERC20 /////////////////////////
    struct WithDrawERC20Data {
        address tokenAddr;
        uint256 amount;
        address userAddr;
        uint256 orderId;
        uint256 chainId;
    } 
    function withdrawERC20(bytes calldata data) public nonReentrant onlyRole(OPERATE_ROLE) {
        WithDrawERC20Data memory withDrawERC20Data = parseWithDrawERC20Data(data);
        require(userWithdrawERC20Orders[withDrawERC20Data.orderId].orderId == 0,"SourceBridge:The order is withdrawed");
        require(withDrawERC20Data.amount > 0,"SourceBridge:No ETH withdraw");
        require(withDrawERC20Data.amount <= IERC20(withDrawERC20Data.tokenAddr).balanceOf(address(this)), "SourceBridge:Insufficient token balance");
        userWithdrawERC20Orders[withDrawERC20Data.orderId] = withDrawERC20Data;
        userWithdrawERC20OrderIds[msg.sender][withDrawERC20Data.tokenAddr].push(withDrawERC20Data.orderId);
        withdrawERC20Amount[withDrawERC20Data.tokenAddr] = withdrawERC20Amount[withDrawERC20Data.tokenAddr].add(withDrawERC20Data.amount);
        uint256 _feePercent;
        if (tokenFeePercentage[withDrawERC20Data.tokenAddr] != 0){
            _feePercent = tokenFeePercentage[withDrawERC20Data.tokenAddr];
        } else {
            _feePercent = feePercent;
        }
        uint256 feeAmount = (withDrawERC20Data.amount * _feePercent) / FEE_DENOMINATOR;
        uint256 userAmount = withDrawERC20Data.amount - feeAmount;
        IERC20(withDrawERC20Data.tokenAddr).safeTransfer(feeReceiver, feeAmount);
        IERC20(withDrawERC20Data.tokenAddr).safeTransfer(withDrawERC20Data.userAddr, userAmount);
       
        emit WithdrawERC20(msg.sender,withDrawERC20Data.tokenAddr,feeReceiver,feeAmount,withDrawERC20Data.userAddr,userAmount,withDrawERC20Data.orderId,withDrawERC20Data.chainId,block.timestamp);
    }

    function parseWithDrawERC20Data(bytes calldata data) internal view returns (WithDrawERC20Data memory) {
        (
            address caller,
            address tokenAddr,
            uint256 amount,
            address userAddr,
            uint256 orderId,
            uint256 chainId,
            bytes memory signature
        ) = abi.decode(
            data,(
                address,
                address,
                uint256,
                address,
                uint256,
                uint256,
                bytes
            )
        );
        require(caller == msg.sender, "SourceBridge: INVALID_USER");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
         bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        WITHDRAWERC20_PERMIT_TYPEHASH,
                        caller,
                        tokenAddr,
                        amount,
                        userAddr,
                        orderId,
                        chainId
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "SourceBridge: INVALID_REQUEST"
        );
        return WithDrawERC20Data({
            tokenAddr:tokenAddr,
            amount:amount,
            userAddr:userAddr,
            orderId:orderId,
            chainId:chainId
        });
    }



    ///////////////  getter setter
    function getUserDepositETH(address user) public view returns(uint256 userAmount) {
        uint256[] memory orderIds = userDepositeETHOrderIds[user];
        for (uint256 i = 0; i < orderIds.length;i++){
            userAmount = userAmount + userDepositeETHOrders[orderIds[i]].amount;
        }
    }

    function getUserWithDrawETH(address user) public view returns(uint256 userAmount) {
        uint256[] memory orderIds = userWithDrawETHOrderIds[user];
        for (uint256 i = 0; i < orderIds.length;i++){
            userAmount = userAmount + userWithDrawETHOrder[orderIds[i]].amount;
        }
    }

    function balance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function setSigner(address _signer) public onlyRole(MANAGE_ROLE) {
        signer = _signer;
    }

    function setReceiver(address _receiver) public onlyRole(MANAGE_ROLE) {
        receiver = _receiver;
    }

    function setFeeReceiver(address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeReceiver = _receiver;
        emit FeeReceiverUpdated(_receiver,block.timestamp);
    }
    function setFeePercent(uint256 _feePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feePercent <= 150, "Fee too high"); // 最多 15%
        feePercent = _feePercent;
        emit FeeUpdated(_feePercent,block.timestamp);
    }
    function setTokenFeePercent(address token,uint256 _feePercent)  external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenFeePercentage[token] = _feePercent;
    }
    function getTokenFeePercent(address token) public view returns(uint256 _feePercent) {
        if (tokenFeePercentage[token] != 0){
            _feePercent = tokenFeePercentage[token];
        } else {
            _feePercent = feePercent;
        }
    }

    // 获取用户的跨链ETH订单
    function getUserDepositETHOrders(address user) public view returns(DepositeData[] memory depositETHOrders){
        uint256[] memory orderIds = userDepositeETHOrderIds[user];
        for (uint256 i = 0;i < orderIds.length;i++){
            depositETHOrders[i] = userDepositeETHOrders[orderIds[i]];
        }
    }

    // 获取用户跨链ERC20订单
    function getUserDepositeERC20Orders(address tokenAddress,address user) public view returns(DepositeERC20Data[] memory depositeERC20Orders){
         uint256[] memory orderIds = userDepositeERC20OrderIds[user][tokenAddress];
         for (uint256 i = 0;i < orderIds.length;i++){
            depositeERC20Orders[i] = userDepositeERC20Orders[orderIds[i]];
         }
    }

    // 获取用户提取的ETH订单
    function getUserWithdrawETHOrders(address user) public view returns(WithDrawETHData[] memory withdrawOrders){
        uint256[] memory orderIds = userWithDrawETHOrderIds[user];
        for (uint256 i = 0;i < orderIds.length;i++){
            withdrawOrders[i] = userWithDrawETHOrder[orderIds[i]];
        }
    }
    // 获取用户提取ERC20的订单
    function getUserWithdrawERC20Orders(address tokenAddress,address user) public view returns(WithDrawERC20Data[] memory withdrawETHOrders){
        uint256[] memory orderIds = userWithdrawERC20OrderIds[user][tokenAddress];
        for (uint256 i = 0;i < orderIds.length;i++){
            withdrawETHOrders[i] = userWithdrawERC20Orders[orderIds[i]];
        }
    }
    

}