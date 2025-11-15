// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../bridge/pijs/UAGToken.sol";

contract RewardDistributeUAG is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
    using SafeMath for uint;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }
    
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    
    function initialize(
        address _signer,
        address _feeReceiver,
        address[4] memory _uacDistributeAddress,
        uint256[4] memory _uacdistributeRadio
        ) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);

        signer = _signer;
        feeReceiver = _feeReceiver;
        uacDistributeAddress = _uacDistributeAddress;
        uacdistributeRadio = _uacdistributeRadio;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("RewardDistributeUAG")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        
    }
    receive() external payable {}

   

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    /////////////////////////////////////////////////////////////*/
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    address public signer;

    mapping(address => mapping(uint256 => MarketMakerWithdrawingProfitsOrder)) public marketMakerWithdrawProfitsOrders;
    mapping(address => uint256[]) marketMakerWithdrawProfitsOrderIds;
    address public feeReceiver;
    mapping(address => uint) public marketMakerNonces;
    mapping(address => uint) public nonces;

    bytes32 private constant PERMIT_MARKETMAKERWITHDRAWPROFITS_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,uint256 nonce)"
        )
    );

    address[4] uacDistributeAddress;
    uint256[4] uacdistributeRadio;
    mapping(address => mapping(uint256 => WithdrawingProfitsOrder)) public userWithdrawProfitsOrders;
    mapping(address => uint256[]) userWithdrawProfitsOrderIds;
    bytes32 private constant PERMIT_WITHDRAWPROFITS_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,address userAddress,address tokenAddress,uint256 amount,address uacAddress,uint256 uacAmount,uint256 withdrawType,uint256 nonce)"
        )
    );

    /*//////////////////////////////////////////////////////////////
                               Struct
    //////////////////////////////////////////////////////////////*/

    struct MarketMakerWithdrawingProfitsOrder{
        uint256 orderId; // 订单号
        address userAddress; // 用户地址
        address tokenAddress; //UAG的地址
        uint256 amount; // 质押UAG数量
        uint256 nonce;
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

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event MarketMakerWithdrawingProfits(address caller,uint256 orderId,address tokenAddress,uint256 amount,address feeReceiver,uint256 fee,uint256 userAmount,uint256 timestamp);
    event WithdrawingProfits(address caller,uint256 orderId,address tokenAddress,uint256 amount,address uacAddress,uint256 uacAmount,uint256 withdrawType,uint256 timestamp);

     /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
     //////////////////////////////////////////////////////////////*/

     // market maker提取收益
    function marketMakerWithdrawingProfits(bytes memory data) public nonReentrant{
        MarketMakerWithdrawingProfitsOrder memory order = parseMarketMakerWithdrawingProfitsOrder(data);
        require(order.userAddress == msg.sender,"RewardDistributeUAG:Invalid msg sender");
        require(marketMakerWithdrawProfitsOrders[msg.sender][order.orderId].orderId == 0,"RewardDistributeUAG:The order is exist");
        require(order.nonce == marketMakerNonces[msg.sender], "RewardDistributeUAG:INVALID_NONCE");
        require(
           UAGToken(order.tokenAddress).transfer(msg.sender, order.amount),
            "MarketMakerStake:Payment transfer failed"
        );
        marketMakerWithdrawProfitsOrders[msg.sender][order.orderId] = order;
        marketMakerWithdrawProfitsOrderIds[msg.sender].push(order.orderId);
        marketMakerNonces[msg.sender]++;

        emit MarketMakerWithdrawingProfits(msg.sender,order.orderId,order.tokenAddress,order.amount,feeReceiver,0,order.amount,block.timestamp);

    }

    function parseMarketMakerWithdrawingProfitsOrder(bytes memory data) internal view returns(MarketMakerWithdrawingProfitsOrder memory) {
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
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
          bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_MARKETMAKERWITHDRAWPROFITS_TYPEHASH,
                        orderId,
                        userAddress,
                        tokenAddress,
                        amount,
                        nonce
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"RewardDistributeUAG:INVALID_REQUEST");

        return MarketMakerWithdrawingProfitsOrder({
            orderId:orderId,
            userAddress: userAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            nonce:nonce,
            createTime: block.timestamp
        });
    }
    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "RewardDistributeUAG:Not Invalid Signature Data");
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

    // staker 提取收益

    // 提取收益
    function withdrawingProfits(bytes memory data) public payable nonReentrant{
        WithdrawingProfitsOrder memory order = parseWithdrawingProfitsOrder(data);
        require(order.userAddress == msg.sender,"RewardDistributeUAG:Invalid msg sender");
        require(userWithdrawProfitsOrders[msg.sender][order.orderId].orderId == 0,"RewardDistributeUAG:The order is exist");
        require(order.uacAmount>0,"RewardDistributeUAG:Invalid uac amount");
        if (order.uacAddress != address(0)){
            require(IERC20(order.uacAddress).allowance(msg.sender, address(this)) >= order.uacAmount,"RewardDistributeUAG:erc20 allowance error");
        }
        require(order.nonce == nonces[msg.sender], "RewardDistributeUAG:INVALID_NONCE");
        
        uint256 address0Amount;
        uint256 address1Amount;
        uint256 address2Amount;
        uint256 address3Amount;
        uint256 allRatio =  uacdistributeRadio[0]+ uacdistributeRadio[1] + uacdistributeRadio[2] + uacdistributeRadio[3];
        if (order.uacAddress == address(0)){
            require(order.uacAmount <= msg.value,"RewardDistributeUAG:not enough eth");
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
                "RewardDistributeUAG:Payment transfer uacDistributeAddress 1 failed"
            );
            address1Amount = order.uacAmount.mul(uacdistributeRadio[1]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[1], address1Amount),
                "RewardDistributeUAG:Payment transfer uacDistributeAddress 1 failed"
            );

            address2Amount = order.uacAmount.mul(uacdistributeRadio[2]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[2], address2Amount),
                "RewardDistributeUAG:Payment transfer uacDistributeAddress 2 failed"
            );

            address3Amount = order.uacAmount.mul(uacdistributeRadio[3]).div(allRatio); 
            require(
                IERC20(order.uacAddress).transferFrom(msg.sender, uacDistributeAddress[3], address3Amount),
                "RewardDistributeUAG:Payment transfer uacDistributeAddress 3 failed"
            );
        }
       
        
        require(
           UAGToken(order.tokenAddress).transfer(msg.sender, order.amount),
            "RewardDistributeUAG:Payment transfer failed"
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
        require(signer == ecrecover(signHash, v, r, s),"RewardDistributeUAG:INVALID_REQUEST");

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
        require(order.userAddress == msg.sender,"RewardDistributeUAG:Invalid msg sender");
        require(userWithdrawProfitsNonConsumptionOrders[msg.sender][order.orderId].orderId == 0,"RewardDistributeUAG:The order is exist");
        // require(order.amount <= userStakeAmounts[msg.sender],"RewardDistributeUAG:withdrawal amount is bigger tha the stake amount");
        require(order.nonce == withdrawingNonConsumptionNonces[msg.sender], "RewardDistributeUAG:INVALID_NONCE");

        require(
           UAGToken(order.tokenAddress).transfer(msg.sender, order.amount),
            "RewardDistributeUAG:Payment transfer failed"
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
        require(signer == ecrecover(signHash, v, r, s),"RewardDistributeUAG:INVALID_REQUEST");

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



    


    function setUacdistributeRadio(uint256[4] memory ratio)  public onlyRole(MANAGE_ROLE) {
        uacdistributeRadio = ratio;
    }

    function getUacdistributeRadio()  public view returns(uint256[4] memory) {
        return uacdistributeRadio;
    }
    function setUacDistributeAddress(address[4] memory distributeAddresses) public  onlyRole(MANAGE_ROLE) {
        uacDistributeAddress = distributeAddresses;
    }
    function getUacDistributeAddress() public view returns(address[4] memory) {
        return uacDistributeAddress;
    }


}