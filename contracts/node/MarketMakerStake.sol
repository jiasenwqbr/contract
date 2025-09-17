// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../bridge/pijs/UAGToken.sol";

contract MarketMakerStake is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
    using SafeMath for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    bool private funcSwitch;
    // 签名者
    address public signer;
    address public uacAddress;
    address public uagAddress;
    address public usdtAddress;
    address private feeAddress;
    mapping(uint => uint) public marketMakerStakeTypeNumber;
    
    event Stake(address caller,uint256 orderId,address tokenAddress,uint256 amount,uint256 startTimestamp,uint256 endTimestamp,uint256 stakeType,uint256 renewable,uint256 status,uint256 renewTime,uint256 timestamp);
    event UnStake(address caller,uint256 orderId,uint256 amount,uint256 timestamp);
    event ReStake(address caller,uint256 orderId,uint256 renewTime,uint256 timestamp);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }
    
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(address _signer,address _uacAddress,address _uagAddress,address _usdtAddress,address _feeAddress) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);

        signer = _signer;
        uacAddress = _uacAddress;
        uagAddress = _uagAddress;
        usdtAddress = _usdtAddress;
        feeAddress = _feeAddress;
        funcSwitch = true;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("MarketMakerStake")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        marketMakerStakeTypeNumber[30 days] = 1000;
        marketMakerStakeTypeNumber[60 days] = 1000;
        marketMakerStakeTypeNumber[90 days] = 1000;
        marketMakerStakeTypeNumber[180 days] = 1000;
    }
    receive() external payable {}

    bytes32 private constant PERMIT_STAKE_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address caller,address tokenAddress,uint256 amount,uint256 startTimestamp,uint256 endTimestamp,uint256 stakeType,uint256 renewable)"
        )
    );

    struct Order {
        uint256 orderId; // 订单号
        address caller;
        address tokenAddress;
        uint256 amount;
        uint256 startTimestamp; // 订单开始时间
        uint256 endTimestamp; // 订单到期时间
        uint256 stakeType;
        uint256 renewable; // 是否允许续期
        uint256 status; // 0 -staking; 1- unstaking  状态
        uint256 renewTime; // 续期时间
    }
    struct RenewOrder {
        uint256 orderId;
        uint256 renewTime;
        uint256 blockTime;
    }
    mapping(address => mapping(uint256 => Order)) public userOrders;
    mapping(address => uint256[]) userOrderIds;
    mapping(address => RenewOrder[]) public userRenewOrders;


    function stake(bytes memory data) public payable nonReentrant {
        require(funcSwitch ,"MarketMakerStake:Function is not enabled");
        Order memory order = parseOrder(data);
        // validate
        require(order.caller == msg.sender,"MarketMakerStake:Invalid msg sender");
        require(order.tokenAddress == usdtAddress,"MarketMakerStake:TokenAddress is invalid");
        require(userOrders[msg.sender][order.orderId].orderId == 0,"MarketMakerStake:Order is exist");
        require(order.amount > 0,"MarketMakerStake:amount should > 0");
        require(order.endTimestamp > order.startTimestamp,"MarketMakerStake:endTimestamp should > startTimestamp");
        require(marketMakerStakeTypeNumber[order.stakeType]!=0,"MarketMakerStake:staketype is error");

        userOrders[msg.sender][order.orderId] = order;
        userOrderIds[msg.sender].push(order.orderId);

        require(
            IERC20(order.tokenAddress).transferFrom(msg.sender, address(this), order.amount),
            "MarketMakerStake:Payment transfer failed"
        );
        emit Stake(msg.sender,order.orderId,order.tokenAddress,order.amount,order.startTimestamp,order.endTimestamp,order.stakeType,order.renewable,order.status,order.renewTime,block.timestamp);

    }

    function parseOrder(bytes memory data) internal view returns(Order memory) {
        (
            uint256 orderId,
            address caller,
            address tokenAddress,
            uint256 amount,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 stakeType,
            uint256 renewable,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                uint256,
                address,
                address,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                bytes
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
          bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_STAKE_TYPEHASH,
                        orderId,
                        caller,
                        tokenAddress,
                        amount,
                        startTimestamp,
                        endTimestamp,
                        stakeType,
                        renewable
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"StakingUAG:INVALID_REQUEST");
        return Order({
            orderId:orderId,
            caller:caller,
            tokenAddress:tokenAddress,
            amount:amount,
            startTimestamp:startTimestamp,
            endTimestamp:endTimestamp,
            stakeType:stakeType,
            renewable:renewable,
            status:0,
            renewTime:0
        });
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "StakingUAG:Not Invalid Signature Data");
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

    function unStake(uint256 stakingId) public  nonReentrant {
        Order memory order = userOrders[msg.sender][stakingId];
        require(order.orderId != 0,"StakingUAG:Order is not exist");
        require(order.status == 0,"StakingUAG:Order is not in staking");
        if (order.renewTime == 0){
            require(order.startTimestamp + order.stakeType >=  block.timestamp);
        } else {
             require(order.renewTime + order.stakeType >=  block.timestamp);
        }

        userOrders[msg.sender][stakingId].status = 1;
        IERC20Upgradeable(usdtAddress).safeTransfer(msg.sender, order.amount);
        emit UnStake(msg.sender,order.orderId,order.amount,block.timestamp);
    }

    function reStake(uint256 stakingId) public   nonReentrant {
        Order memory order = userOrders[msg.sender][stakingId];
        require(order.orderId != 0,"StakingUAG:Order is not exist");
        require(order.status == 0,"StakingUAG:Order is not in staking");
        if (order.renewTime == 0){
            require(order.startTimestamp + order.stakeType >=  block.timestamp);
        } else {
             require(order.renewTime + order.stakeType >=  block.timestamp);
        }
        userOrders[msg.sender][stakingId].renewTime = block.timestamp;
        RenewOrder memory renewOrder = RenewOrder({
            orderId:order.orderId,
            renewTime:block.timestamp,
            blockTime:block.timestamp
        });
        userRenewOrders[msg.sender].push(renewOrder);

        emit ReStake(msg.sender,order.orderId,renewOrder.renewTime,block.timestamp);

    }

    ///////////////////// setters
    function setFuncSwith(bool _funcSwitch) public onlyRole(MANAGE_ROLE) {
        funcSwitch = _funcSwitch;
    }
    function setFeeAddress(address _feeAddress)  public onlyRole(MANAGE_ROLE) {
        feeAddress = _feeAddress;
    }

    ////////////////////  getters
    function getOrder(address userAddress,uint256 orderId) public view returns (Order memory){
        return userOrders[userAddress][orderId];
    }

    function getUserOrders(address userAddress) public view returns(Order[] memory) {
        uint256[] memory orderIds =  userOrderIds[userAddress];
        Order[] memory orders = new Order[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length;i++ ){
            orders[i] = userOrders[userAddress][orderIds[i]];
        }
        return orders;
    }

    function getRenewOrders(address userAddress) public view returns(Order[] memory) {
       RenewOrder[] memory renewOrders =  userRenewOrders[userAddress];
       Order[] memory orders = new Order[](renewOrders.length);
       for (uint256 i =0;i<renewOrders.length;i++){
            orders[i] = userOrders[userAddress][renewOrders[i].orderId];
       }
       return orders;
    }
}