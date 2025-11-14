// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract ValidateNode is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {

        bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
        bytes32 public DOMAIN_SEPARATOR;
        bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
        bool private funcSwitch;
        // 签名者
        address public signer;
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
                               Struct
        //////////////////////////////////////////////////////////////*/
        struct NodeInfo {
            string name;
            address nodeAddress;
            uint8 nodeType; // 托管验证者 1、自建节点 2
            uint256 purchaseDuration;
            address agentAddress;
            uint256 expiryDate;
            uint256 createTime;
            address[] agentAddresses;
            address[] clientAddress;
        }

        struct AgentInfo {
            string name;
            address agentAddress;
            address[] validitorNodeAddresses;
            address[] clientAddresses;
            uint256 purchaseDuration;
            uint256 expiryDate;
            uint256 payAmount;
            uint256 createTime;
        }

        struct ClientInfo {
            address clientAddress;
            uint256[] validatorNodeId;
            address[] agentAddresses; 
        }

        /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
        /////////////////////////////////////////////////////////////*/

        mapping(address => NodeInfo) public validiteNodes;   // nodeAddress => NodeInfo{...}
        mapping(address => AgentInfo) public agentInfos;   // agent address => AgentInfo{...}
        mapping(address => ClientInfo) public clientInfos; // client address => ClientInfo{...}
        mapping(address => address[]) public agentNodeAddresses;   // agent address => nodeAddress[]
        mapping(address => address[]) public clientAgentAddresses;   // client address => agentAddress[]



        /*//////////////////////////////////////////////////////////////
                                 EVENTS
        //////////////////////////////////////////////////////////////*/

        /*//////////////////////////////////////////////////////////////
                               MODIFIERS
        //////////////////////////////////////////////////////////////*/


        /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
        //////////////////////////////////////////////////////////////*/

        function addNode(NodeInfo memory node) external onlyRole(OPERATE_ROLE) {
            require(validiteNodes[node.nodeAddress].nodeAddress == address(0),"ValidateNode:node is exist");
            validiteNodes[node.nodeAddress] = node;
            if (node.agentAddress!= address(0)){
                agentNodeAddresses[node.agentAddress].push(node.nodeAddress);
            }
        }

        function addAgent(AgentInfo memory agent) external onlyRole(OPERATE_ROLE) {
            require(agentInfos[agent.agentAddress].agentAddress != address(0),"ValidateNode:agent is exist");
            agentInfos[agent.agentAddress] = agent;
        }




}