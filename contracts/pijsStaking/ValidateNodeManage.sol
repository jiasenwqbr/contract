// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ValidateNode.sol";

contract ValidateNodeManage is  Initializable,
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

        function initialize(address _signer,address _validatorContractAddress,address _feeReceiver,address _usdtAddress) public initializer {
            __AccessControlEnumerable_init();
            __ReentrancyGuard_init();
            __UUPSUpgradeable_init();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(MANAGE_ROLE, msg.sender);

            signer = _signer;
            validatorContractAddress = _validatorContractAddress;
            feeReceiver = _feeReceiver;
            usdtAddress = _usdtAddress;
            uint256 chainId = block.chainid;
            DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("NodeManage")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );

            // mapping(uint256 => ValidteNodeProduct) public validteNodeProducts;mapping(uint256 => AgentNodeProduct) public agentNodeProducts;
            // initalize product 
            uint256 stakeType1 = 60 * 60 * 24  * 365 * 1; // 1 year
            validteNodeProducts[stakeType1] = ValidteNodeProduct({
                stakeType:stakeType1,
                token:usdtAddress,
                amount:10 ether,
                enabled:true
            });
            uint256 stakeType2 = 60 * 60 * 24 * 365 * 2; // 2 year
            validteNodeProducts[stakeType2] = ValidteNodeProduct({
                stakeType:stakeType2,
                token:usdtAddress,
                amount:20 ether,
                enabled:true
            });
            uint256 stakeType3 = 60 * 60 * 24 * 365 * 3; // 3 year
            validteNodeProducts[stakeType3] = ValidteNodeProduct({
                stakeType:stakeType3,
                token:usdtAddress,
                amount:20 ether,
                enabled:true
            });

            uint256 agentStakeType1 = 30 days;
            agentNodeProducts[agentStakeType1] = AgentNodeProduct({
                stakeType:agentStakeType1,
                token:address(0),
                amount:30 ether,
                enabled:true
            });

            uint256 agentStakeType2 = 60 days;
            agentNodeProducts[agentStakeType2] = AgentNodeProduct({
                stakeType:agentStakeType2,
                token:address(0),
                amount:60 ether,
                enabled:true
            });

            uint256 agentStakeType3 = 90 days;
            agentNodeProducts[agentStakeType3] = AgentNodeProduct({
                stakeType:agentStakeType3,
                token:address(0),
                amount:90 ether,
                enabled:true
            });

        }
        /*//////////////////////////////////////////////////////////////
                               Struct
        //////////////////////////////////////////////////////////////*/

        struct BuyValidateOrder {
            uint256 orderId;
            string name;
            uint256 purchaseDuration;
            address tokenAddress;
            uint256 payAmount;
            address feeTo;
            uint256 expiryDate;
            address agentAddress;
            uint256 nonce;
        }

        struct RegistNodeOrder {
            uint256 orderId;
            uint8 nodeType;
            string name;
            uint256 nonce;
            
        }

        struct RegistAgentOrder {
            uint256 orderId;
            string name;
            uint256 purchaseDuration;
            address agentAddress;
            address feeTo;
            uint256 expiryDate;
            uint256 payAmount;
            uint256 nonce;
        }

        struct RenewAgentOrder {
            uint256 orderId;
            uint256 purchaseDuration;
            uint256 expiryDate;
            address agentAddress;
            uint256 payAmount;
            uint256 nonce;
        }

        struct ValidteNodeProduct {
            uint256 stakeType;
            address token;
            uint256 amount;
            bool enabled;
        }

        struct AgentNodeProduct {
            uint256 stakeType;
            address token;
            uint256 amount;
            bool enabled;
        }

        /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
        /////////////////////////////////////////////////////////////*/
        // PERMIT_BUYVALIDITENODE_TYPEHASH
        // bytes32 private constant PERMIT_BUYVALIDITENODE_TYPEHASH = keccak256(
        //     abi.encodePacked(
        //         "Permit(uint256 orderId,string name,uint256 purchaseDuration,address tokenAddress,uint256 payAmount,address feeTo,uint256 expiryDate,address agentAddress,uint256 nonce)"
        //     )
        // );
        bytes32 private constant PERMIT_BUYVALIDITENODE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 purchaseDuration,address tokenAddress,uint256 payAmount,address feeTo,uint256 expiryDate,address agentAddress,uint256 nonce)"
            )
        );
        // PERMIT_REGISTAGENT_TYPEHASH
        bytes32 private constant PERMIT_REGISTAGENT_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 purchaseDuration,address agentAddress,address feeTo,uint256 expiryDate,uint256 payAmount,uint256 nonce)"
            )
        );

        bytes32 private constant PERMIT_RENEWAGENT_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 purchaseDuration,uint256 expiryDate,address agentAddress,uint256 payAmount,uint256 nonce)"
            )
        );
        

        address public validatorContractAddress;
        address public feeReceiver;
        address public usdtAddress;
        mapping(address => uint) public buyValidateNodeNonces;
        mapping(address => uint) public registValidateNodeNonces;
        mapping(address => uint) public renewAgentNonces;

        mapping(uint256 => BuyValidateOrder) public buyValidateOrders;
        mapping(uint256 => RenewAgentOrder) public renewAgentOrders;
        mapping(uint256 => RegistAgentOrder) public registAgentOrders;

        mapping(address => uint256[]) public buyValidateNodeOrderIds;
        mapping(address => uint256[]) public registAgentOrderIds;
        mapping(address => uint256[]) public renewAgentOrderIds;

        mapping(uint256 => ValidteNodeProduct) public validteNodeProducts;
        mapping(uint256 => AgentNodeProduct) public agentNodeProducts;

        /*//////////////////////////////////////////////////////////////
                                 EVENTS
        //////////////////////////////////////////////////////////////*/
        event BuyNode(uint256 orderId,string name,uint256 purchaseDuration,address tokenAddress,uint256 payAmount,address feeTo,uint256 expiryDate,address agentAddress,uint256 nonce,uint256 createTime);
        event RegistNode(uint8 nodeType,string name,address nodeAddress,uint256 nonce,uint256 createTime);
        event RegistAgent(uint256 orderId,string name,uint256 purchaseDuration,address agentAddress,address feeTo,uint256 expiryDate,uint256 payAmount,uint256 nonce,uint256 createTime);
        event RenewAgent(uint256 orderId,uint256 purchaseDuration,uint256 expiryDate,address agentAddress,uint256 payAmount,uint256 nonce,uint256 createTime);
        
        /*//////////////////////////////////////////////////////////////
                               MODIFIERS
        //////////////////////////////////////////////////////////////*/


        /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
        //////////////////////////////////////////////////////////////*/

        /// buy validate node
        function buyNode(bytes memory data) public  nonReentrant {
            BuyValidateOrder memory order = parseBuyValidateOrder(data);
            require(order.nonce == buyValidateNodeNonces[msg.sender], "NodeManage:INVALID_NONCE");
            require(buyValidateOrders[order.orderId].purchaseDuration == 0,"NodeManage:order is exist");
            require(order.tokenAddress == usdtAddress,"NodeManage:tokenAddress must be usdt");
            require(order.payAmount > 0,"NodeManage:payAmount >0");
            require(feeReceiver != address(0),"0 address");
            require(feeReceiver == order.feeTo,"NodeManage:Invalid feeTo");
            require(validteNodeProducts[order.purchaseDuration].stakeType != 0,"NodeManage:stake type is not exist");
            require(validteNodeProducts[order.purchaseDuration].amount <= order.payAmount,"NodeManage:amount is not enough");
            
            buyValidateOrders[order.orderId] = order;
            buyValidateNodeOrderIds[msg.sender].push(order.orderId);
            buyValidateNodeNonces[msg.sender]++;
            
            require(
                IERC20(order.tokenAddress).transferFrom(msg.sender, feeReceiver, order.payAmount),
                "NodeManage:Payment transfer usdt failed"
            );

            emit BuyNode(order.orderId,order.name,order.purchaseDuration,order.tokenAddress,order.payAmount,order.feeTo,order.expiryDate,order.agentAddress,order.nonce,block.timestamp);
        }


        function parseBuyValidateOrder(bytes memory data )  internal view returns(BuyValidateOrder memory) {
            (
                uint256 orderId,
                string memory name,
                uint256 purchaseDuration,
                address tokenAddress,
                uint256 payAmount,
                address feeTo,
                uint256 expiryDate,
                address agentAddress,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    string,
                    uint256,
                    address,
                    uint256,
                    address,
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
                            PERMIT_BUYVALIDITENODE_TYPEHASH,
                            orderId,
                            // name,
                            purchaseDuration,
                            tokenAddress,
                            payAmount,
                            feeTo,
                            expiryDate,
                            agentAddress,
                            nonce
                        )
                    )
                )
            );
            require(signer == ecrecover(signHash, v, r, s),"NodeManage:INVALID_REQUEST");
        
            return BuyValidateOrder({
                orderId:orderId,
                name: name,
                purchaseDuration: purchaseDuration,
                tokenAddress:tokenAddress,
                payAmount: payAmount,
                feeTo:feeTo,
                expiryDate: expiryDate,
                agentAddress: agentAddress,
                nonce: nonce
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

        /// regist Node to be a validate node
        function registNode( 
            uint8 nodeType,
            string memory name,
            uint256 nonce,
            address nodeAddress) public onlyRole(OPERATE_ROLE) nonReentrant {
            require(nodeType == 1 || nodeType == 2 ,"NodeManage:Invalid node type");
            require(nonce == registValidateNodeNonces[msg.sender], "NodeManage:INVALID_NONCE");
            if (nodeType == 1) {
                require(buyValidateNodeOrderIds[nodeAddress].length>0,"NodeManage:not buy node");
            }
            require(ValidateNode(validatorContractAddress).getAgentInfo(nodeAddress).agentAddress == address(0),"NodeManage:agent node can not to be validate node");

            // to be real node
            ValidateNode.NodeInfo memory node;
            if (nodeType == 1) {
                BuyValidateOrder memory order = buyValidateOrders[buyValidateNodeOrderIds[nodeAddress][0]];
                address[] memory agentAddress = new address[](1);
                address[] memory clientAddress = new address[](0); 
                agentAddress[0] = order.agentAddress;
                node = ValidateNode.NodeInfo({
                        name:name,
                        nodeAddress:nodeAddress,
                        nodeType:nodeType,
                        purchaseDuration:order.purchaseDuration,
                        agentAddress:order.agentAddress,
                        expiryDate:order.expiryDate,
                        createTime:block.timestamp,
                        agentAddresses:agentAddress,
                        clientAddress:clientAddress
                    }
                );
            } else {
                node = ValidateNode.NodeInfo({
                        name:name,
                        nodeAddress:nodeAddress,
                        nodeType:nodeType,
                        purchaseDuration:0,
                        agentAddress:address(0),
                        expiryDate:0,
                        createTime:block.timestamp,
                        agentAddresses:new address[](0),
                        clientAddress:new address[](0)
                    }
                );
            }
            ValidateNode(validatorContractAddress).addNode(node);
            registValidateNodeNonces[msg.sender]++;

            emit RegistNode(nodeType,name,nodeAddress,nonce,block.timestamp);
            
        }

        /// registAgent
        function registAgent(bytes memory data) public payable nonReentrant {
            RegistAgentOrder memory order = parseRegistAgentOrder(data);
            require(order.nonce == registValidateNodeNonces[msg.sender], "NodeManage:INVALID_NONCE");
            require(registAgentOrders[order.orderId].purchaseDuration == 0,"NodeManage:order is exist");
            require(order.payAmount > 0,"NodeManage:payAmount >0");
            require(feeReceiver != address(0),"0 address");
            require(feeReceiver == order.feeTo,"NodeManage:Invalid feeTo");
            require(msg.sender == order.agentAddress,"NodeManage:invalid agentAddress");
            require(ValidateNode(validatorContractAddress).getValidatorNodeInfo(order.agentAddress).nodeAddress == address(0),"NodeManage:validate node can not to be agent");
            require(agentNodeProducts[order.purchaseDuration].stakeType != 0,"NodeManage:stake type is not exist");
            require(agentNodeProducts[order.purchaseDuration].amount <= order.payAmount,"NodeManage:amount is not enough");
            registAgentOrders[order.orderId] = order;
            registAgentOrderIds[msg.sender].push(order.orderId);
            registValidateNodeNonces[msg.sender]++;
            
            address[] memory validitorNodeAddresses;
            address[] memory clientAddresses;
            ValidateNode.AgentInfo memory agentInfo = ValidateNode.AgentInfo({
                name:order.name,
                agentAddress:order.agentAddress,
                validitorNodeAddresses:validitorNodeAddresses,
                clientAddresses:clientAddresses,
                purchaseDuration:order.purchaseDuration,
                expiryDate:order.expiryDate,
                payAmount:order.payAmount,
                createTime:block.timestamp

            });
            
            ValidateNode(validatorContractAddress).addAgent(agentInfo);

            (bool success1, ) = payable(feeReceiver).call{value: order.payAmount}("");
            require(success1, "NodeManage:Native transfer to failed");

            emit RegistAgent(order.orderId,order.name,order.purchaseDuration,order.agentAddress,order.feeTo,order.expiryDate,order.payAmount,order.nonce,block.timestamp);

        }

        function parseRegistAgentOrder(bytes memory data) internal view returns(RegistAgentOrder memory) {
            (
                uint256 orderId,
                string memory name,
                uint256 purchaseDuration,
                address agentAddress,
                address feeTo,
                uint256 expiryDate,
                uint256 payAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    string,
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
                            PERMIT_REGISTAGENT_TYPEHASH,
                            orderId,
                            // name,
                            purchaseDuration,
                            agentAddress,
                            feeTo,
                            expiryDate,
                            payAmount,
                            nonce
                        )
                    )
                )
            );
            require(signer == ecrecover(signHash, v, r, s),"NodeManage:INVALID_REQUEST");

            return RegistAgentOrder({
                orderId:orderId,
                name:name,
                purchaseDuration:purchaseDuration,
                agentAddress:agentAddress,
                feeTo:feeTo,
                expiryDate:expiryDate,
                payAmount:payAmount,
                nonce:nonce
            });
        }

        // renewAgent
        function renewAgent(bytes memory data) public payable nonReentrant {
            RenewAgentOrder memory order = parseRenewAgentOrder(data);
            require(order.nonce == renewAgentNonces[msg.sender], "NodeManage:INVALID_NONCE");
            require(order.payAmount > 0,"NodeManage:payAmount >0");
            require(feeReceiver != address(0),"0 address");
            ValidateNode.AgentInfo memory agent =  ValidateNode(validatorContractAddress).getAgentInfo(msg.sender);
            require(agent.purchaseDuration != 0,"NodeManage:agent is not exist");
            
            // require(agent.expiryDate <= block.timestamp,"NodeManage:Not yet due");
            agent.purchaseDuration = order.purchaseDuration;
            agent.expiryDate = order.expiryDate;
            agent.payAmount = order.payAmount;
            ValidateNode(validatorContractAddress).renewAgent(agent);
            renewAgentOrders[order.orderId] = order;
            renewAgentOrderIds[order.agentAddress].push(order.orderId);
            renewAgentNonces[msg.sender]++;
            (bool success3, ) = payable(feeReceiver).call{value: order.payAmount}("");
            require(success3, "Native transfer to feeFeceiver failed");

            emit RenewAgent(order.orderId,order.purchaseDuration,order.expiryDate,order.agentAddress,order.payAmount,order.nonce,block.timestamp);
            

        }

        function parseRenewAgentOrder(bytes memory data) internal view returns(RenewAgentOrder memory){
            (
                uint256 orderId,
                uint256 purchaseDuration,
                uint256 expiryDate,
                address agentAddress,
                uint256 payAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    uint256,
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
                            PERMIT_RENEWAGENT_TYPEHASH,
                            orderId,
                            purchaseDuration,
                            expiryDate,
                            agentAddress,
                            payAmount,
                            nonce
                        )
                    )
                )
            );
            require(signer == ecrecover(signHash, v, r, s),"NodeManage:INVALID_REQUEST");
            return RenewAgentOrder({
                orderId:orderId,
                purchaseDuration:purchaseDuration,
                expiryDate:expiryDate,
                agentAddress:agentAddress,
                payAmount:payAmount,
                nonce:nonce
            });
        }


        function getRegistAgentOrder(uint256 orderId) public view returns(RegistAgentOrder memory) {
            return registAgentOrders[orderId];
        }

    }