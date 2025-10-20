// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../bridge/pijs/UAGToken.sol";
interface BurnableERC20 {
     function mint(address to, uint256 amount) external;
     function burnFrom(address account, uint256 amount) external;
}
contract StakingUAG is 
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
    using SafeMath for uint;
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    bool private funcSwitch;
    // 签名者
    address public signer;

    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }
    
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    address public uagAddress;
    address public uacAddress;
    address private feeAddress;
    uint256 public stakeAmountMin;
    uint256 public stakeAmountMax;
    uint256 public withdrawalFeePersentage;
    address[4] uacDistributeAddress;
    uint256[4] uacdistributeRadio;

    function initialize(
        address _signer,
        address _uagAddress,
        address _uacAddress,
        address _feeAddress,
        uint256 _stakeAmountMin,
        uint256 _stakeAmountMax,
        uint256 _withdrawalFeePersentage,
        address gensisNodeDistribute,
        address ecoDevAddress,
        address insuranceWarehouse
        ) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        
        signer = _signer;
        uagAddress = _uagAddress;
        funcSwitch = true;
        feeAddress = _feeAddress;
        stakeAmountMin = _stakeAmountMin;
        stakeAmountMax = _stakeAmountMax;
        withdrawalFeePersentage = _withdrawalFeePersentage;
        uacAddress = _uacAddress;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("StakingUAG")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        uacDistributeAddress[0] = address(0);
        uacDistributeAddress[1] = gensisNodeDistribute;
        uacDistributeAddress[2] = ecoDevAddress;
        uacDistributeAddress[3] = insuranceWarehouse;
        uacdistributeRadio[0] = 3;
        uacdistributeRadio[1] = 2;
        uacdistributeRadio[2] = 5;
        uacdistributeRadio[3] = 10;


    }

    bytes32 private constant PERMIT_STAKE_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,uint256 burnAmount,uint256 energyValue)"
        )
    );

    bytes32 private constant PERMIT_WITHDRAWALSTAKE_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount)"
        )
    );
    bytes32 private constant PERMIT_WITHDRAWPROFITS_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,address uacAddress,uint256 uacAmount,uint256 withdrawType,uint256 nonce)"
        )
    );

    mapping(address => uint) public nonces;


    struct Order{
        uint256 orderId; // 订单号
        address userAddress; // 用户地址
        address tokenAddress; //UAG的地址
        uint256 amount; // 质押UAG数量
        uint256 burnAmount; //销毁UAG数量
        uint256 energyValue; // 获取的能量值
        uint256 createTime;
        uint8 status; // 0 -staking; 1- unstaking  状态
    }

    struct WithdrawalOrder{
        uint256 orderId; // 订单号
        address userAddress; // 用户地址
        address tokenAddress; //UAG的地址
        uint256 amount; // 质押UAG数量
        uint256 createTime;
    }

    struct WithdrawingProfitsOrder{
        uint256 orderId; // 订单号
        address userAddress; // 用户地址
        address tokenAddress; //UAG的地址
        uint256 amount; // 质押UAG数量
        address uacAddress;
        uint256 uacAmount;
        uint256 withdrawType;
        uint256 createTime;
        uint256 nonce;
    }


    mapping(address => mapping(uint256 => Order)) public userOrders;
    mapping(address => uint256[]) userOrderIds;
    mapping(address => uint256) public userStakeAmounts;

    mapping(address => mapping(uint256 => WithdrawalOrder)) public userWithdrawalOrders;
    mapping(address => uint256[]) userWithdrawalOrderIds;

    mapping(address => mapping(uint256 => WithdrawingProfitsOrder)) public userWithdrawProfitsOrders;
    mapping(address => uint256[]) userWithdrawProfitsOrderIds;

    event StakeUAG(address caller,uint256 orderId,address tokenAddress,uint256 amount,uint256 burnAmount,uint256 energyValue,uint256 userStakeAmount,uint256 timestamp);
    event UnStake(address caller,uint256 orderId,address tokenAddress,uint256 amount,uint256 timestamp);
    event WithdrawingProfits(address caller,uint256 orderId,address tokenAddress,uint256 amount,address uacAddress,uint256 uacAmount,uint256 withdrawType,uint256 timestamp);

    // 质押UAG
    function stakeUAG(bytes memory data)  public payable nonReentrant{
        require(funcSwitch,"StakingUAG:Function is not enabled");
        Order memory order = parseOrder(data);
        // validate
        require(order.userAddress == msg.sender,"StakingUAG:Invalid msg sender");
        require(userOrders[msg.sender][order.orderId].orderId == 0,"StakingUAG:The order is exist");
        require(order.amount.add(userStakeAmounts[msg.sender]) >= stakeAmountMin && order.amount.add(userStakeAmounts[msg.sender]) <= stakeAmountMax,"StakingUAG:The pledge amount is not within a reasonable range");
        // require(order.burnAmount>0,"StakingUAG:Invalid burn amount");
        // require(order.tokenAddress == uagAddress,"StakingUAG:Invalid token address");
        // require(IERC20(uagAddress).allowance(msg.sender, address(this)) >= order.amount.add(order.burnAmount),"StakingUAG:erc20 allowance error");

        require(order.amount !=0 || order.burnAmount!=0,"StakingUAG:amount and burnAmount shoud not all eq 0");
        if (order.amount !=0){
            require(
                IERC20(order.tokenAddress).transferFrom(msg.sender, address(this), order.amount),
                "StakingUAG:Payment transfer failed"
             );
        }
        

        if (order.burnAmount!=0){
             UAGToken(order.tokenAddress).burnFrom(order.userAddress,order.burnAmount);
        }
       
        
        userOrders[msg.sender][order.orderId] = order;
        userOrderIds[msg.sender].push(order.orderId);
        userStakeAmounts[msg.sender] = userStakeAmounts[msg.sender].add(order.amount);

        emit StakeUAG(msg.sender,order.orderId,order.tokenAddress,order.amount,order.burnAmount,order.energyValue,userStakeAmounts[msg.sender],block.timestamp);
    }
    // "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,uint256 burnAmount,uint256 energyValue)"
    function parseOrder(bytes memory data) internal view returns(Order memory) {
        (
            uint256 orderId,
            address userAddress,
            address tokenAddress,
            uint256 amount,
            uint256 burnAmount,
            uint256 energyValue,
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
                        userAddress,
                        tokenAddress,
                        amount,
                        burnAmount,
                        energyValue
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"StakingUAG:INVALID_REQUEST");
        
        return Order({
            orderId:orderId,
            userAddress: userAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            burnAmount: burnAmount,
            energyValue: energyValue,
            createTime: block.timestamp,
            status: 0
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

    // 撤出
    function unStake(bytes memory data) public nonReentrant{
        require(funcSwitch,"StakingUAG:Function is not enabled");
        WithdrawalOrder memory order = parseWithdrawalOrder(data);
        // require(userOrders[msg.sender][order.orderId].orderId != 0,"StakingUAG:The order is not exist");
        require(order.userAddress == msg.sender,"StakingUAG:Invalid msg sender");
        require(userWithdrawalOrders[msg.sender][order.orderId].orderId == 0,"StakingUAG:The unstake order is  exist");
        // require(order.tokenAddress == uagAddress,"StakingUAG:Invalid token address");
        require(order.amount <= userStakeAmounts[msg.sender],"StakingUAG:withdrawal amount is bigger tha the stake amount");
        uint256 fee = userStakeAmounts[msg.sender].mul(withdrawalFeePersentage).div(1000);
        uint256 userReceiveAmount = userStakeAmounts[msg.sender].sub(fee);
        // require(IERC20(order.tokenAddress).balanceOf(address(this)) >= userReceiveAmount,"StakingUAG:Insufficient payment amount");

        require(
            IERC20(order.tokenAddress).transfer(feeAddress, fee),
            "StakingUAG:Payment transfer failed"
        );

        require(
             IERC20(order.tokenAddress).transfer(msg.sender, userReceiveAmount),
            "StakingUAG:Payment transfer failed"
        );

        userWithdrawalOrders[msg.sender][order.orderId] = order;
        userWithdrawalOrderIds[msg.sender].push(order.orderId);
        userStakeAmounts[msg.sender] = 0;

        emit UnStake(msg.sender,order.orderId,order.tokenAddress,order.amount,block.timestamp);

    }

    function parseWithdrawalOrder(bytes memory data) internal view returns(WithdrawalOrder memory) {
        (
            uint256 orderId,
            address userAddress,
            address tokenAddress,
            uint256 amount,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                uint256,
                address,
                address,
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
                        PERMIT_WITHDRAWALSTAKE_TYPEHASH,
                        orderId,
                        userAddress,
                        tokenAddress,
                        amount
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"StakingUAG:INVALID_REQUEST");

        return WithdrawalOrder({
            orderId:orderId,
            userAddress: userAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            createTime: block.timestamp
        });
    }
   

    
    // 提取收益
    function withdrawingProfits(bytes memory data) public payable nonReentrant{
        WithdrawingProfitsOrder memory order = parseWithdrawingProfitsOrder(data);
        require(funcSwitch,"StakingUAG:Function is not enabled");
        require(order.userAddress == msg.sender,"StakingUAG:Invalid msg sender");
        require(userWithdrawProfitsOrders[msg.sender][order.orderId].orderId == 0,"StakingUAG:The order is exist");
        // require(order.tokenAddress == uagAddress,"StakingUAG:Invalid token address");
        // require(order.amount <= userStakeAmounts[msg.sender],"StakingUAG:withdrawal amount is bigger tha the stake amount");
        // require(order.uacAddress == uacAddress,"StakingUAG:Invalid uac token address");
        require(order.uacAmount>0,"StakingUAG:Invalid uac amount");
        if (order.uacAddress != address(0)){
            require(IERC20(order.uacAddress).allowance(msg.sender, address(this)) >= order.uacAmount,"StakingUAG:erc20 allowance error");
        }
        require(order.nonce == nonces[msg.sender], "StakingUAG:INVALID_NONCE");
        // UAGToken(uagAddress).mint(msg.sender,order.amount);

        
        uint256 address0Amount;
        uint256 address1Amount;
        uint256 address2Amount;
        uint256 address3Amount;
        uint256 allRatio =  uacdistributeRadio[0]+ uacdistributeRadio[1] + uacdistributeRadio[2] + uacdistributeRadio[3];
        if (order.uacAddress == address(0)){
            require(order.uacAmount <= msg.value,"StakingUAG:not enough eth");
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
            // BurnableERC20(order.uacAddress).burnFrom(msg.sender,address0Amount);
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD , address0Amount),
                "StakingUAG:Payment transfer uacDistributeAddress 1 failed"
            );
            address1Amount = order.uacAmount.mul(uacdistributeRadio[1]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[1], address1Amount),
                "StakingUAG:Payment transfer uacDistributeAddress 1 failed"
            );

            address2Amount = order.uacAmount.mul(uacdistributeRadio[2]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[2], address2Amount),
                "StakingUAG:Payment transfer uacDistributeAddress 2 failed"
            );

            address3Amount = order.uacAmount.mul(uacdistributeRadio[3]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[3], address3Amount),
                "StakingUAG:Payment transfer uacDistributeAddress 3 failed"
            );
        }
       
        
        require(
           UAGToken(order.tokenAddress).transfer(msg.sender, order.amount),
            "StakingUAG:Payment transfer failed"
        );

        userWithdrawProfitsOrders[msg.sender][order.orderId] = order;
        userWithdrawProfitsOrderIds[msg.sender].push(order.orderId);
        nonces[msg.sender]++;
        emit WithdrawingProfits(msg.sender,order.orderId,order.tokenAddress,order.amount,order.uacAddress,order.uacAmount,order.withdrawType,block.timestamp);


    }
    function parseWithdrawingProfitsOrder(bytes memory data) internal view returns(WithdrawingProfitsOrder memory) {
        (
            uint256 orderId,
            address userAddress,
            address tokenAddress,
            uint256 amount,
            address _uacAddress,
            uint256 uacAmount,
            uint256 withdrawType,
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
                        PERMIT_WITHDRAWPROFITS_TYPEHASH,
                        orderId,
                        userAddress,
                        tokenAddress,
                        amount,
                        _uacAddress,
                        uacAmount,
                        withdrawType,
                        nonce
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"StakingUAG:INVALID_REQUEST");

        return WithdrawingProfitsOrder({
            orderId:orderId,
            userAddress: userAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            uacAddress:_uacAddress,
            uacAmount: uacAmount,
            withdrawType:withdrawType,
            nonce:nonce,
            createTime: block.timestamp
        });
    }

    struct WithdrawingProfitsNonConsumptionOrder{
        uint256 orderId; // 订单号
        address userAddress; // 用户地址
        address tokenAddress; //UAG的地址
        uint256 amount; // 质押UAG数量
        uint256 withdrawType;
        uint256 createTime;
        uint256 nonce;
    }
    mapping(address => uint) public withdrawingNonConsumptionNonces;
    mapping(address => mapping(uint256 => WithdrawingProfitsNonConsumptionOrder)) public userWithdrawProfitsNonConsumptionOrders;
    mapping(address => uint256[]) userWithdrawProfitsNonConsumptionOrderIds;
    bytes32 private constant PERMIT_WITHDRAWPROFITSNON_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,uint256 withdrawType,uint256 nonce)"
        )
    );
    event WithdrawingProfitsNonConsumptionNonces(address caller,uint256 orderId,address tokenAddress,uint256 amount,uint256 withdrawType,uint256 timestamp);

    function withdrawingProfitsNonConsumption(bytes memory data) public payable nonReentrant{
        WithdrawingProfitsNonConsumptionOrder memory order = parseWithdrawingNonConsumptionrder(data);
        require(funcSwitch,"StakingUAG:Function is not enabled");
        require(order.userAddress == msg.sender,"StakingUAG:Invalid msg sender");
        require(userWithdrawProfitsNonConsumptionOrders[msg.sender][order.orderId].orderId == 0,"StakingUAG:The order is exist");
        // require(order.amount <= userStakeAmounts[msg.sender],"StakingUAG:withdrawal amount is bigger tha the stake amount");
        require(order.nonce == withdrawingNonConsumptionNonces[msg.sender], "StakingUAG:INVALID_NONCE");

        require(
           UAGToken(order.tokenAddress).transfer(msg.sender, order.amount),
            "StakingUAG:Payment transfer failed"
        );

        userWithdrawProfitsNonConsumptionOrders[msg.sender][order.orderId] = order;
        userWithdrawProfitsNonConsumptionOrderIds[msg.sender].push(order.orderId);
        withdrawingNonConsumptionNonces[msg.sender]++;
        emit WithdrawingProfitsNonConsumptionNonces(msg.sender,order.orderId,order.tokenAddress,order.amount,order.withdrawType,block.timestamp);

    }

     function parseWithdrawingNonConsumptionrder(bytes memory data) internal view returns(WithdrawingProfitsNonConsumptionOrder memory) {
        (
            uint256 orderId,
            address userAddress,
            address tokenAddress,
            uint256 amount,
            uint256 withdrawType,
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
                        PERMIT_WITHDRAWPROFITSNON_TYPEHASH,
                        orderId,
                        userAddress,
                        tokenAddress,
                        amount,
                        withdrawType,
                        nonce
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"StakingUAG:INVALID_REQUEST");

        return WithdrawingProfitsNonConsumptionOrder({
            orderId:orderId,
            userAddress: userAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            withdrawType:withdrawType,
            nonce:nonce,
            createTime: block.timestamp
        });
    }

    ///////////////////// setters
    function setFuncSwith(bool _funcSwitch) public onlyRole(MANAGE_ROLE) {
        funcSwitch = _funcSwitch;
    }

    function setWithdrawalFeePersentage(uint256 _withdrawalFeePersentage) public onlyRole(MANAGE_ROLE) {
        withdrawalFeePersentage = _withdrawalFeePersentage;
    }
    function getWithdrawalFeePersentage() public view returns (uint256) {
        return withdrawalFeePersentage;
    }
    
    function setFeeAddress(address _feeAddress)  public onlyRole(MANAGE_ROLE) {
        feeAddress = _feeAddress;
    }

    function getUserOrders(address userAddress) public view returns(Order[] memory) {
        uint256[] memory orderIds =  userOrderIds[userAddress];
        Order[] memory orders = new Order[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length;i++ ){
            orders[i] = userOrders[userAddress][orderIds[i]];
        }
        return orders;
    }

    function getUserWithdrawalOrders(address userAddress) public view returns(WithdrawalOrder[] memory) {
        uint256[] memory orderIds = userWithdrawalOrderIds[userAddress];
        WithdrawalOrder[] memory orders = new  WithdrawalOrder[](orderIds.length);
        for (uint256 i = 0;i<orderIds.length;i++){
            orders[i] = userWithdrawalOrders[userAddress][orderIds[i]];
        }
        return orders;
    }

    function getUserWithdrawProfitsOrders(address userAddress) public view returns(WithdrawingProfitsOrder[] memory) {
        uint256[] memory orderIds = userWithdrawProfitsOrderIds[userAddress];
        WithdrawingProfitsOrder[] memory orders = new WithdrawingProfitsOrder[](orderIds.length);
        for (uint256 i = 0;i<orderIds.length;i++){
            orders[i] = userWithdrawProfitsOrders[userAddress][orderIds[i]];
        }
        return orders;
    }

    function setUacDistributeAddress(address[4] memory distributeAddresses) public  onlyRole(MANAGE_ROLE) {
        uacDistributeAddress = distributeAddresses;
    }
    function getUacDistributeAddress() public view returns(address[4] memory) {
        return uacDistributeAddress;
    }

    function setUacdistributeRadio(uint256[4] memory ratio)  public onlyRole(MANAGE_ROLE) {
        uacdistributeRadio = ratio;
    }

    function getUacdistributeRadio()  public view returns(uint256[4] memory) {
        return uacdistributeRadio;
    }

    function setStakeAmountLimit(uint256 _stakeAmountMin,uint256 _stakeAmountMax) public onlyRole(MANAGE_ROLE) {
        stakeAmountMax = _stakeAmountMax;
        stakeAmountMin = _stakeAmountMin;
    }
    function getStakeAmountLimit() public view returns (uint256,uint256) {
        return (stakeAmountMin,stakeAmountMax);
    }

    
    

}