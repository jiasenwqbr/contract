// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./ValidateNode.sol";
contract Staking is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {

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

        function initialize(address _signer,address _validatorContractAddress) public initializer {
            __AccessControlEnumerable_init();
            __ReentrancyGuard_init();
            __UUPSUpgradeable_init();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(MANAGE_ROLE, msg.sender);
            signer = _signer;
            validatorContractAddress = _validatorContractAddress;

            uint256 chainId = block.chainid;
            DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("Staking")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );

            stakeTypes[30 days] = true;
            stakeTypes[60 days] = true;
            stakeTypes[90 days] = true;
            stakeTypes[180 days] = true;
            stakeTypes[360 days] = true;
        }

        /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
        /////////////////////////////////////////////////////////////*/
        address public validatorContractAddress;
        mapping(uint256 => ValidatorStakeOrder) validatorStakeOrders;
        mapping(address => uint256[]) validateStakeOrderIds;

        mapping(uint256 => AgentStakeOrder) agentStakeOrders;
        mapping(address => uint256[]) agentStakeOrderIds;

        mapping(uint256 => ClientStakeOrder) clientStakeOrders;
        mapping(address => uint256[]) clientStakeOrderIds;

        // PERMIT_VALIDATORSTAKE_TYPEHASH
        bytes32 private constant PERMIT_VALIDATORSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce)"
            )
        );
        bytes32 private constant PERMIT_AGENTSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce)"
            )
        );
        bytes32 private constant PERMIT_CLIENTSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,address validatorAddress,address agentAddress,address clientAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce)"
            )
        );
        mapping(address => uint) public validatorStakeNonces;
        mapping(address => uint) public agentStakeNonces;
        mapping(address => uint) public clientStakeNonces;
        mapping(uint256 => bool) public stakeTypes;

        /*//////////////////////////////////////////////////////////////
                               Struct
        //////////////////////////////////////////////////////////////*/
        struct ValidatorStakeOrder {
            uint256 orderId;
            address validatorAddress;
            address agentAddress;
            uint256 stakeDuration;
            uint256 stakeAmount;
            uint256 nonce;
            uint256 stakeTime;
        }

        struct AgentStakeOrder {
            uint256 orderId;
            address validatorAddress;
            address agentAddress;
            uint256 stakeDuration;
            uint256 stakeAmount;
            uint256 nonce;
            uint256 stakeTime;
        }

        struct ClientStakeOrder {
            uint256 orderId;
            address validatorAddress;
            address agentAddress;
            address clientAddress;
            uint256 stakeDuration;
            uint256 stakeAmount;
            uint256 nonce;
            uint256 stakeTime;
        }
        

        /*//////////////////////////////////////////////////////////////
                                 EVENTS
        //////////////////////////////////////////////////////////////*/

        event ValidiatorStake(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce,uint256 stakeTime);
        event AgentStake(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce,uint256 stakeTime);
        event ClientStake(uint256 orderId,address validatorAddress,address agentAddress,address clientAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce,uint256 stakeTime);

        /*//////////////////////////////////////////////////////////////
                               MODIFIERS
        //////////////////////////////////////////////////////////////*/


        /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
        //////////////////////////////////////////////////////////////*/
        function validiatorStake(bytes memory data) public  nonReentrant payable {
            ValidatorStakeOrder memory order = parseValidatorStakeOrder(data);

            // is validator

            require(order.nonce == validatorStakeNonces[msg.sender],"Staking:INVALID_NONCE");
            require(order.validatorAddress == msg.sender,"Staking:Invalid user");
            require(order.stakeAmount > 0,"Staking:stakeAmount >0");
            require(order.stakeDuration > 0,"Staking:stakeDuration >0");
            require(validatorStakeOrders[order.orderId].stakeDuration == 0,"Staking:Order is exist");
            require(stakeTypes[order.stakeDuration] == true,"Staking:stake type is disabled");

            validatorStakeNonces[msg.sender]++;
            validatorStakeOrders[order.orderId] = order;
            validateStakeOrderIds[msg.sender].push(order.orderId);
            ValidateNode(validatorContractAddress).validatorStakeUpdate(order.validatorAddress,order.agentAddress);

            emit ValidiatorStake(order.orderId,order.validatorAddress,order.agentAddress,order.stakeDuration,order.stakeAmount,order.nonce,order.stakeTime);
        }

        function parseValidatorStakeOrder(bytes memory data) internal view returns(ValidatorStakeOrder memory) {
            (
                uint256 orderId,
                address validatorAddress,
                address agentAddress,
                uint256 stakeDuration,
                uint256 stakeAmount,
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
                            PERMIT_VALIDATORSTAKE_TYPEHASH,
                            orderId,
                            validatorAddress,
                            agentAddress,
                            stakeDuration,
                            stakeAmount,
                            nonce
                        )
                    )
                )
            );
            require(signer == ecrecover(signHash, v, r, s),"NodeManage:INVALID_REQUEST");
            return ValidatorStakeOrder({
                orderId:orderId,
                validatorAddress:validatorAddress,
                agentAddress:agentAddress,
                stakeDuration:stakeDuration,
                stakeAmount:stakeAmount,
                nonce:nonce,
                stakeTime:block.timestamp
            });

        }

        function splitSignature(
            bytes memory sig
        ) internal pure returns (uint8, bytes32, bytes32) {
            require(sig.length == 65, "NodeManage:Not Invalid Signature Data");
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

        function agentStake(bytes memory data) public  nonReentrant payable {
            AgentStakeOrder memory order = parseAgentStakeOrder(data);
            require(order.nonce == agentStakeNonces[msg.sender],"Staking:INVALID_NONCE");
            require(order.agentAddress == msg.sender,"Staking:Invalid user");
            require(order.stakeAmount > 0,"Staking:stakeAmount >0");
            require(order.stakeDuration > 0,"Staking:stakeDuration >0");
            require(agentStakeOrders[order.orderId].stakeDuration == 0,"Staking:Order is exist");
            require(stakeTypes[order.stakeDuration] == true,"Staking:stake type is disabled");

            agentStakeNonces[msg.sender]++;
            agentStakeOrders[order.orderId] = order;
            agentStakeOrderIds[msg.sender].push(order.orderId);
            ValidateNode(validatorContractAddress).agentStakeUpdate(order.validatorAddress,order.agentAddress);

            emit AgentStake(order.orderId,order.validatorAddress,order.agentAddress,order.stakeDuration,order.stakeAmount,order.nonce,order.stakeTime);

        }

        function parseAgentStakeOrder(bytes memory data) internal view returns(AgentStakeOrder memory ){
            (
                uint256 orderId,
                address validatorAddress,
                address agentAddress,
                uint256 stakeDuration,
                uint256 stakeAmount,
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
                            PERMIT_AGENTSTAKE_TYPEHASH,
                            orderId,
                            validatorAddress,
                            agentAddress,
                            stakeDuration,
                            stakeAmount,
                            nonce
                        )
                    )
                )
            );
            require(signer == ecrecover(signHash, v, r, s),"NodeManage:INVALID_REQUEST");
            return AgentStakeOrder({
                orderId:orderId,
                validatorAddress:validatorAddress,
                agentAddress:agentAddress,
                stakeDuration:stakeDuration,
                stakeAmount:stakeAmount,
                nonce:nonce,
                stakeTime:block.timestamp
            });

        }

        function clientStake(bytes memory data) public  nonReentrant payable {
            ClientStakeOrder memory order = parseClientStakeOrder(data);
            require(order.nonce == clientStakeNonces[msg.sender],"Staking:INVALID_NONCE");
            require(order.clientAddress == msg.sender,"Staking:Invalid user");
            require(order.stakeAmount > 0,"Staking:stakeAmount >0");
            require(order.stakeDuration > 0,"Staking:stakeDuration >0");
            require(clientStakeOrders[order.orderId].stakeDuration == 0,"Staking:Order is exist");
            require(stakeTypes[order.stakeDuration] == true,"Staking:stake type is disabled");

            clientStakeNonces[msg.sender]++;
            clientStakeOrders[order.orderId] = order;
            clientStakeOrderIds[msg.sender].push(order.orderId);
            ValidateNode(validatorContractAddress).clientStakeUpdate(order.validatorAddress,order.agentAddress,order.clientAddress);

            emit ClientStake(order.orderId,order.validatorAddress,order.agentAddress,order.clientAddress,order.stakeDuration,order.stakeAmount,order.nonce,order.stakeTime);

        }
         function parseClientStakeOrder(bytes memory data) internal view returns(ClientStakeOrder memory ){
            (
                uint256 orderId,
                address validatorAddress,
                address agentAddress,
                address clientAddress,
                uint256 stakeDuration,
                uint256 stakeAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    address,
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
                            PERMIT_CLIENTSTAKE_TYPEHASH,
                            orderId,
                            validatorAddress,
                            agentAddress,
                            clientAddress,
                            stakeDuration,
                            stakeAmount,
                            nonce
                        )
                    )
                )
            );
            require(signer == ecrecover(signHash, v, r, s),"NodeManage:INVALID_REQUEST");
            return ClientStakeOrder({
                orderId:orderId,
                validatorAddress:validatorAddress,
                agentAddress:agentAddress,
                clientAddress:clientAddress,
                stakeDuration:stakeDuration,
                stakeAmount:stakeAmount,
                nonce:nonce,
                stakeTime:block.timestamp
            });

        }


        function setStakeType(uint256 stakeProid,bool enabled) public onlyRole(MANAGE_ROLE) {
            stakeTypes[stakeProid] = enabled;
        }



    }