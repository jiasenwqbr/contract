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
interface BurnableERC20 {
     function mint(address to, uint256 amount) external;
     function burnFrom(address account, uint256 amount) external;
}
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
    
    address[4] uacDistributeAddress;
    uint256[4] uacdistributeRadio;

   
    event Stake(address caller,uint256 orderId,address tokenAddress,uint256 amount,uint256 startTimestamp,uint256 endTimestamp,uint256 stakeType,uint256 renewable,uint256 status,uint256 renewTime,uint256 timestamp);
    event UnStake(address caller,uint256 orderId,uint256 amount,uint256 timestamp);
    event ReStake(address caller,uint256 orderId,uint256 renewTime,uint256 timestamp);
    event WithdrawingProfits(address caller,uint256 orderId,address tokenAddress,uint256 amount,address feeReceiver,uint256 fee,uint256 userAmount,uint256 timestamp);
    event ReleaseStakes(address caller,uint256 orderId,address tokenAddress,uint256 amount,address uacAddress,uint256 uacAmount,uint256 releaseType,uint256 timestamp);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }
    
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(
        address _signer,
        address _uacAddress,
        address _uagAddress,
        address _usdtAddress,
        address _feeAddress,
        address gensisNodeDistribute,
        address ecoDevAddress,
        address insuranceWarehouse) public initializer {
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
        marketMakerStakeTypeNumber[180 days] =1000;
        marketMakerStakeTypeNumber[360 days] =1000;

        uacDistributeAddress[0] = address(0);
        uacDistributeAddress[1] = gensisNodeDistribute;
        uacDistributeAddress[2] = ecoDevAddress;
        uacDistributeAddress[3] = insuranceWarehouse;
        uacdistributeRadio[0] = 15;
        uacdistributeRadio[1] = 10;
        uacdistributeRadio[2] = 25;
        uacdistributeRadio[3] = 50;

        releaseTypeMap[0 ] = ReleaseOption({
            releaseType:30,
            expendUacPercent:200
        });
        releaseTypeMap[10 days] = ReleaseOption({
            releaseType:10 days,
            expendUacPercent:150
        });
        releaseTypeMap[20 days] = ReleaseOption({
            releaseType:20 days,
            expendUacPercent:100
        });
        releaseTypeMap[30 days] = ReleaseOption({
            releaseType:30 days,
            expendUacPercent:50
        });
    }
    receive() external payable {}

    bytes32 private constant PERMIT_STAKE_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address caller,address tokenAddress,uint256 amount,uint256 startTimestamp,uint256 endTimestamp,uint256 stakeType,uint256 renewable)"
        )
    );
    bytes32 private constant PERMIT_WITHDRAWPROFITS_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,uint256 nonce)"
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
    mapping(address => uint) public nonces;

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
    // "Permit(uint256 orderId,address caller,address tokenAddress,uint256 amount,uint256 startTimestamp,uint256 endTimestamp,uint256 stakeType,uint256 renewable)"
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
        require(signer == ecrecover(signHash, v, r, s),"MarketMakerStake:INVALID_REQUEST");
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
        require(sig.length == 65, "MarketMakerStake:Not Invalid Signature Data");
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
        require(order.orderId != 0,"MarketMakerStake:Order is not exist");
        require(order.status == 0,"MarketMakerStake:Order is not in staking");
        if (order.renewTime == 0){
            require(order.startTimestamp + order.stakeType <=  block.timestamp,"MarketMakerStake:Pledge not yet expired");
        } else {
            require(order.renewTime + order.stakeType <=  block.timestamp,"MarketMakerStake:Pledge not yet expired");
        }

        uint256 fee = order.amount.mul(withdrawPercent).div(1000);
        uint256 userReceiveAmount = order.amount.sub(fee);
        // require(IERC20(order.tokenAddress).balanceOf(address(this)) >= userReceiveAmount,"StakingUAG:Insufficient payment amount");

        require(
            IERC20(order.tokenAddress).transfer(feeAddress, fee),
            "StakingUAG:Payment transfer failed"
        );

        require(
             IERC20(order.tokenAddress).transfer(msg.sender, userReceiveAmount),
            "StakingUAG:Payment transfer failed"
        );

        userOrders[msg.sender][stakingId].status = 1;
        // IERC20Upgradeable(usdtAddress).safeTransfer(msg.sender, order.amount);
        emit UnStake(msg.sender,order.orderId,order.amount,block.timestamp);
    }

    function reStake(uint256 stakingId) public   nonReentrant {
        Order memory order = userOrders[msg.sender][stakingId];
        require(order.orderId != 0,"MarketMakerStake:Order is not exist");
        require(order.status == 0,"MarketMakerStake:Order is not in staking");
        if (order.renewTime == 0){
            require(order.startTimestamp + order.stakeType <= block.timestamp,"MarketMakerStake:Pledge not yet expired");
        } else {
             require(order.renewTime + order.stakeType <=  block.timestamp,"MarketMakerStake:Pledge not yet expired");
        }
        userOrders[msg.sender][stakingId].renewTime = block.timestamp.add(order.stakeType);
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

    function setMarketMakerStakeTypeNumber(uint256 stakeType,uint256 num) public onlyRole(MANAGE_ROLE) {
        marketMakerStakeTypeNumber[stakeType] = num;
    }
    function getMarketMakerStakeTypeNumber(uint256 stakeType) public view returns(uint256) {
        return  marketMakerStakeTypeNumber[stakeType];
    }
    function setReleaseTypeMap(uint256 _releaseType,uint256 _expendUacPercent)  public onlyRole(MANAGE_ROLE) {
        releaseTypeMap[_releaseType] = ReleaseOption({
            releaseType:_releaseType,
            expendUacPercent:_expendUacPercent
        });
    }
    function setUacdistributeRadio(uint256[4] memory radio) public onlyRole(MANAGE_ROLE){
        uacdistributeRadio[0] = radio[0];
        uacdistributeRadio[1] = radio[1];
        uacdistributeRadio[2] = radio[2];
        uacdistributeRadio[3] = radio[3];
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
    function getReleaseTypeMap(uint256 _releaseType) public view returns(ReleaseOption memory) {
        return releaseTypeMap[_releaseType];
    }
    function getReleaseOrder(address userAddress) public view returns(ReleaseOrder[] memory){
        uint256[] memory ids = userReleaseOrderIds[userAddress];
        ReleaseOrder[] memory orders = new ReleaseOrder[](ids.length);
        for (uint256 i = 0;i<ids.length;i++){
            orders[i] = userReleaseOrders[userAddress][ids[i]];
        }
        return orders;
    }

    function getWithDrawOrder(address userAddress) public view returns(WithdrawingProfitsOrder[] memory){
        uint256[] memory ids = userWithdrawProfitsOrderIds[userAddress];
        WithdrawingProfitsOrder[] memory orders = new WithdrawingProfitsOrder[](ids.length);
          for (uint256 i = 0;i<ids.length;i++){
            orders[i] = userWithdrawProfitsOrders[userAddress][ids[i]];
        }
        return orders;
    }
    function getUacdistributeRadio() public view returns(uint256[4] memory){
        return uacdistributeRadio;
    }

    // 释放
    struct ReleaseOrder {
        uint256 orderId;
        address userAddress;
        address tokenAddress;
        uint256 amount;
        address uacAddress;
        uint256 uacAmount;
        uint256 releaseType;
        uint256 nonce;
        uint256 createTime;
    }
    mapping(address => uint256) releaseNonces;
    struct ReleaseOption {
        uint256 releaseType;
        uint256 expendUacPercent;
    }
    mapping(uint256 => ReleaseOption) releaseTypeMap;
    mapping(address => mapping(uint256 => ReleaseOrder)) public userReleaseOrders;
    mapping(address => uint256[]) userReleaseOrderIds;
    function releaseStake(bytes memory data) public payable nonReentrant{
        ReleaseOrder memory order = parseReleaseOrder(data);
        require(funcSwitch,"MarketMakerStake:Function is not enabled");
        require(order.userAddress == msg.sender,"MarketMakerStake:Invalid msg sender");
        require(order.nonce == releaseNonces[msg.sender], "MarketMakerStake:INVALID_NONCE");
        require(userReleaseOrders[msg.sender][order.orderId].orderId == 0,"MarketMakerStake:The order is exist");
        // require(order.tokenAddress == uagAddress,"MarketMakerStake:Invalid token address");
        // require(order.uacAddress == uacAddress,"MarketMakerStake:Invalid uac token address");
        
        if (order.releaseType!=0){
             require(releaseTypeMap[order.releaseType].releaseType != 0,"MarketMakerStake:release type is not exist");
        }
        if (order.uacAddress != address(0)){
            require(IERC20(order.uacAddress).allowance(msg.sender, address(this)) >= order.uacAmount,"MarketMakerStake:erc20 allowance error");
        }
        uint256 address0Amount;
        uint256 address1Amount;
        uint256 address2Amount;
        uint256 address3Amount;
        uint256 allRatio =  uacdistributeRadio[0]+ uacdistributeRadio[1] + uacdistributeRadio[2] + uacdistributeRadio[3];
        if (order.uacAddress == address(0)){
            require(order.uacAmount <= msg.value,"MarketMakerStake:not enough eth");
            address0Amount = order.uacAmount.mul(uacdistributeRadio[0]).div(allRatio);
            // burn
            (bool success0, ) = payable(0xC8B67F0ac126278dee62f0ada69941872494AbC5).call{value: address0Amount}("");
            require(success0, "Native burn transfer failed");

            address1Amount = order.uacAmount.mul(uacdistributeRadio[1]).div(allRatio);
            (bool success1, ) = payable(uacDistributeAddress[1]).call{value: address1Amount}("");
            require(success1, "Native transfer to address1 failed");

            address2Amount = order.uacAmount.mul(uacdistributeRadio[2]).div(allRatio);
            (bool success2, ) = payable(uacDistributeAddress[2]).call{value: address2Amount}("");
            require(success2, "Native transfer to address2 failed");

            address3Amount = order.uacAmount.mul(uacdistributeRadio[3]).div(allRatio);
            (bool success3, ) = payable(uacDistributeAddress[3]).call{value: address3Amount}("");
            require(success3, "Native transfer to address3 failed");
        } else {
            // burn
            address0Amount = order.uacAmount.mul(uacdistributeRadio[0]).div(allRatio); 
            BurnableERC20(order.uacAddress).burnFrom(msg.sender,address0Amount);
            address1Amount = order.uacAmount.mul(uacdistributeRadio[1]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[1], address1Amount),
                "MarketMakerStake:Payment transfer uacDistributeAddress 1 failed"
            );

            address2Amount = order.uacAmount.mul(uacdistributeRadio[2]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[2], address2Amount),
                "MarketMakerStake:Payment transfer uacDistributeAddress 2 failed"
            );

            address3Amount = order.uacAmount.mul(uacdistributeRadio[3]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[3], address3Amount),
                "MarketMakerStake:Payment transfer uacDistributeAddress 3 failed"
            );
        }

       
        userReleaseOrders[msg.sender][order.orderId] = order;
        userReleaseOrderIds[msg.sender].push(order.orderId);
        releaseNonces[msg.sender]++;

        emit ReleaseStakes(msg.sender,order.orderId,order.tokenAddress,order.amount,order.uacAddress,order.uacAmount,order.releaseType,block.timestamp);

    }
    bytes32 private constant PERMIT_RELEASE_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,address uacAddress,uint256 uacAmount,uint256 releaseType,uint256 nonce)"
        )
    );
    function parseReleaseOrder(bytes memory data) internal view returns(ReleaseOrder memory) {
         (
            uint256 orderId,
            address userAddress,
            address tokenAddress,
            uint256 amount,
            address _uacAddress,
            uint256 uacAmount,
            uint256 releaseType,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                uint256,
                address,
                address,
                uint256,
                address,
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
                        PERMIT_RELEASE_TYPEHASH,
                        orderId,
                        userAddress,
                        tokenAddress,
                        amount,
                        _uacAddress,
                        uacAmount,
                        releaseType,
                        nonce
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"MarketMakerStake:INVALID_REQUEST");
        return ReleaseOrder({
            orderId:orderId,
            userAddress: userAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            uacAddress:_uacAddress,
            uacAmount: uacAmount,
            releaseType:releaseType,
            nonce:nonce,
            createTime: block.timestamp
        });
    }

    struct WithdrawingProfitsOrder{
        uint256 orderId; // 订单号
        address userAddress; // 用户地址
        address tokenAddress; //UAG的地址
        uint256 amount; // 质押UAG数量
        uint256 nonce;
        uint256 createTime;
    }
    mapping(address => mapping(uint256 => WithdrawingProfitsOrder)) public userWithdrawProfitsOrders;
    mapping(address => uint256[]) userWithdrawProfitsOrderIds;

    uint256 withdrawPercent;
    uint256  constant  DENOMINATOR = 1000;
    address feeReceiver;
    // 提取收益
    function withdrawingProfits(bytes memory data) public nonReentrant{
        WithdrawingProfitsOrder memory order = parseWithdrawingProfitsOrder(data);
        require(funcSwitch,"MarketMakerStake:Function is not enabled");
        require(order.userAddress == msg.sender,"MarketMakerStake:Invalid msg sender");
        require(userWithdrawProfitsOrders[msg.sender][order.orderId].orderId == 0,"MarketMakerStake:The order is exist");
        // require(order.tokenAddress == uagAddress,"MarketMakerStake:Invalid token address");
        require(order.nonce == nonces[msg.sender], "MarketMakerStake:INVALID_NONCE");

        // uint256 fee =  order.amount.mul(withdrawPercent).div(DENOMINATOR);
        // uint256 userAmount = order.amount.sub(fee);
        // if (fee > 0){
        //     require(
        //          UAGToken(order.tokenAddress).transfer(feeReceiver, fee),
        //     "MarketMakerStake:Payment transfer fee failed"
        //     );
        // }
        require(
           UAGToken(order.tokenAddress).transfer(msg.sender, order.amount),
            "MarketMakerStake:Payment transfer failed"
        );
        userWithdrawProfitsOrders[msg.sender][order.orderId] = order;
        userWithdrawProfitsOrderIds[msg.sender].push(order.orderId);
        nonces[msg.sender]++;

        emit WithdrawingProfits(msg.sender,order.orderId,order.tokenAddress,order.amount,feeReceiver,0,order.amount,block.timestamp);

    }

    function parseWithdrawingProfitsOrder(bytes memory data) internal view returns(WithdrawingProfitsOrder memory) {
        (
            uint256 orderId,
            address userAddress,
            address tokenAddress,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                uint256,
                address,
                address,
                uint256,
                uint256,
                bytes
            )
        );
        // (uint256 orderId,address userAddress,address tokenAddress,uint256 amount,uint256 nonce)
         (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
          bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_WITHDRAWPROFITS_TYPEHASH,
                        orderId,
                        userAddress,
                        tokenAddress,
                        amount,
                        nonce
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"MarketMakerStake:INVALID_REQUEST");

        return WithdrawingProfitsOrder({
            orderId:orderId,
            userAddress: userAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            nonce:nonce,
            createTime: block.timestamp
        });
    }

    function setWithdrawPercent(uint256 _withdrawPercent) public onlyRole(MANAGE_ROLE) {
        withdrawPercent = _withdrawPercent;
    }
    function getWithdrawPercent() public view returns(uint256){
        return withdrawPercent;
    }

    function setFeeReceiver(address _feeReceiver) public onlyRole(MANAGE_ROLE) {
        feeReceiver = _feeReceiver;
    }
    function getFeeReceiver() public view returns(address){
        return feeReceiver;
    }
    function setUacDistributeAddress(address[4] memory distributeAddresses) public  onlyRole(MANAGE_ROLE) {
        uacDistributeAddress = distributeAddresses;
    }
    function getUacDistributeAddress() public view returns(address[4] memory) {
        return uacDistributeAddress;
    }

   
    
}