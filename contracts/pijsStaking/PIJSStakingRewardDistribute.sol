// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./ValidateNode.sol";
contract PIJSStakingRewardDistribute is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
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

    function initialize(address _signer) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);

        signer = _signer;
        uint256 chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("StakingRewardDistribute")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    /////////////////////////////////////////////////////////////*/
    mapping(uint256 =>  WithdrawRewardOrder) public withdrawRewardOrders;
    mapping(address => uint256[] ) public userWithdrawRewardOrderIds;

    bytes32 private constant PERMIT_WITHDRAWREWARD_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,uint256 amount,address beneficiaryAddress,uint256 nonce)"
        )
    );
    mapping(address => uint) public withdrawNonces;
    mapping(uint256 => uint256) public rewardRecords;

    /*//////////////////////////////////////////////////////////////
                            Struct
    //////////////////////////////////////////////////////////////*/
    struct WithdrawRewardOrder{
        uint256 orderId;
        uint256 amount;
        address beneficiaryAddress;
        uint256 withdrawTime;
        uint256 nonce;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event WithdrawReward(uint256 orderId,uint256 amount,address beneficiaryAddress,uint256 nonce,uint256 withdrawTime);
    event GenerateRewards(address operator,uint256 yyyymmdd,uint256 amount,uint256 amountSum,uint256 createTime);
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function generateRewards(uint256 yyyymmdd) public onlyRole(OPERATE_ROLE) nonReentrant payable {
        require(msg.value > 0,"StakingRewardDistribute:msg.value should > 0");
        rewardRecords[yyyymmdd] = rewardRecords[yyyymmdd] + msg.value;
        
        emit GenerateRewards(msg.sender,yyyymmdd,msg.value,rewardRecords[yyyymmdd],block.timestamp);
    }

    function withdrawReward(bytes memory data) public nonReentrant {
        WithdrawRewardOrder memory order = parseWithdrawReward(data);
        require(order.nonce == withdrawNonces[msg.sender],"StakingRewardDistribute:INVALID_NONCE");
        // require(msg.sender == order.beneficiaryAddress,"StakingRewardDistribute:invalid user address");
        require(order.beneficiaryAddress != address(0),"StakingRewardDistribute:address 0 is not allowed");
        require(withdrawRewardOrders[order.orderId].beneficiaryAddress == address(0),"StakingRewardDistribute:withwarded");

        withdrawRewardOrders[order.orderId] = order;
        userWithdrawRewardOrderIds[msg.sender].push(order.orderId);
        withdrawNonces[msg.sender]++;

        (bool success, ) = payable(msg.sender).call{value: order.amount }("");
        require(success, "StakingRewardDistribute:Native  transfer failed");

        emit WithdrawReward(order.orderId,order.amount,order.beneficiaryAddress,order.nonce,order.withdrawTime);
    }

    function parseWithdrawReward(bytes memory data) internal view returns (WithdrawRewardOrder memory) {
        (
            uint256 orderId,
            uint256 amount,
            address beneficiaryAddress,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                uint256,
                uint256,
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
                        PERMIT_WITHDRAWREWARD_TYPEHASH,
                        orderId,
                        amount,
                        beneficiaryAddress,
                        nonce
                    )
                )
            )
        );
        require(signer == ecrecover(signHash, v, r, s),"StakingRewardDistribute:INVALID_REQUEST");
        return WithdrawRewardOrder({
            orderId:orderId,
            amount:amount,
            beneficiaryAddress:beneficiaryAddress,
            withdrawTime:block.timestamp,
            nonce:nonce
        });
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "StakingRewardDistribute:Not Invalid Signature Data");
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

}
