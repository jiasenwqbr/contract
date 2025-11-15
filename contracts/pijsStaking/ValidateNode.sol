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
                    keccak256(bytes("ValidateNode")),
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
            address[] validatorNodeAddresses;
            address[] agentAddresses; 
        }

        /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
        /////////////////////////////////////////////////////////////*/

        mapping(address => NodeInfo) public validiteNodes;   // nodeAddress => NodeInfo{...}
        mapping(address => AgentInfo) public agentInfos;   // agent address => AgentInfo{...}
        mapping(address => ClientInfo) public clientInfos; // client address => ClientInfo{...}
        



        /*//////////////////////////////////////////////////////////////
                                 EVENTS
        //////////////////////////////////////////////////////////////*/

        /*//////////////////////////////////////////////////////////////
                               MODIFIERS
        //////////////////////////////////////////////////////////////*/


        /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
        //////////////////////////////////////////////////////////////*/

        //////////////////////////// business logic  /////////////////////////////
        function addNode(NodeInfo memory node) external onlyRole(OPERATE_ROLE) {
            require(validiteNodes[node.nodeAddress].nodeAddress == address(0),"ValidateNode:node is exist");
            validiteNodes[node.nodeAddress] = node;
        }

        function addAgent(AgentInfo memory agent) external onlyRole(OPERATE_ROLE) {
            require(agentInfos[agent.agentAddress].agentAddress != address(0),"ValidateNode:agent is exist");
            agentInfos[agent.agentAddress] = agent;
        }

        
        function renewAgent(AgentInfo memory agent) external onlyRole(OPERATE_ROLE) {
            agentInfos[agent.agentAddress].expiryDate = agent.expiryDate;
            agentInfos[agent.agentAddress].purchaseDuration = agent.purchaseDuration;
            agentInfos[agent.agentAddress].payAmount = agent.payAmount;
        }

        // update releationship
        function validatorStakeUpdate(address validatorAddress,address agentAddress) external onlyRole(OPERATE_ROLE) {
            require(validatorAddress != address(0),"ValidateNode:0 address");
            require(agentAddress != address(0),"ValidateNode:0 address");
            NodeInfo memory node = validiteNodes[validatorAddress];
            require(node.nodeAddress != address(0),"ValidateNode:node is not exist");
            bool isExist = false;
            for (uint256 i = 0;i < node.agentAddresses.length;i++){
                if (agentAddress ==  node.agentAddresses[i]){
                    isExist = true;
                    break;
                }
            }
            if (isExist == false){
                validiteNodes[validatorAddress].agentAddresses.push(agentAddress);
            }
        }

        function agentStakeUpdate(address validatorAddress,address agentAddress) external onlyRole(OPERATE_ROLE) {
            require(validatorAddress != address(0),"ValidateNode:0 address");
            require(agentAddress != address(0),"ValidateNode:0 address");
            NodeInfo memory node = validiteNodes[validatorAddress];
            require(node.nodeAddress != address(0),"ValidateNode:node is not exist");
            bool isExist = false;
            for (uint256 i = 0;i < node.agentAddresses.length;i++){
                if (agentAddress ==  node.agentAddresses[i]){
                    isExist = true;
                    break;
                }
            }
            if (isExist == false){
                validiteNodes[validatorAddress].agentAddresses.push(agentAddress);
            }

            AgentInfo memory agent = agentInfos[agentAddress];
            require(agent.agentAddress != address(0),"ValidateNode:agent is not exist");
            bool validatorIsExist = false;
            for (uint256 i = 0; i < agent.validitorNodeAddresses.length;i++){
                if (agent.validitorNodeAddresses[i] == validatorAddress){
                    validatorIsExist = true;
                    break;
                }
            }
            if (validatorIsExist == false){
                agentInfos[agentAddress].validitorNodeAddresses.push(validatorAddress);
            }
        }

        function clientStakeUpdate(address validatorAddress,address agentAddress,address clientAddress) external onlyRole(OPERATE_ROLE) {
            require(validatorAddress != address(0),"ValidateNode:0 address");
            require(clientAddress != address(0),"ValidateNode:0 address");
            NodeInfo memory node = validiteNodes[validatorAddress];
            require(node.nodeAddress != address(0),"ValidateNode:node is not exist");
            bool isExist = false;
            for (uint256 i = 0; i < node.clientAddress.length;i++){
                if (node.clientAddress[i] == clientAddress){
                    isExist = true;
                    break;
                }
            }
            if (isExist == false){
                validiteNodes[validatorAddress].clientAddress.push(clientAddress);
            }
            if (agentAddress != address(0)){
                AgentInfo memory agent =  agentInfos[agentAddress];
                bool isValidatorExist = false;
                for (uint256 i = 0;i < agent.validitorNodeAddresses.length;i++){
                    if (agent.validitorNodeAddresses[i] == validatorAddress){
                        isValidatorExist = true;
                        break;
                    }
                }
                if (isValidatorExist == false){
                    agentInfos[agentAddress].validitorNodeAddresses.push(validatorAddress);
                }

                bool isClientExist = false;
                for (uint256 i = 0;i < agent.clientAddresses.length;i++){
                    if (agent.clientAddresses[i] == clientAddress){
                        isClientExist = true;
                        break;
                    }
                }
                if (isClientExist == false){
                    agentInfos[agentAddress].clientAddresses.push(clientAddress);
                }
            }

            ClientInfo memory client = clientInfos[clientAddress];
            if (client.clientAddress == address(0)){
                address[] memory vAddresses;
                vAddresses[0] = validatorAddress;
                address[] memory aAddresses;
                if (agentAddress!= address(0)){
                   aAddresses[0] = agentAddress;
                }

                ClientInfo memory cli = ClientInfo({
                    clientAddress:clientAddress,
                    validatorNodeAddresses:vAddresses,
                    agentAddresses:aAddresses

                });
                clientInfos[clientAddress] = cli;
            } else {
                bool isValidatorExist = false;
                for (uint256 i = 0;i < client.validatorNodeAddresses.length;i++){
                    if (client.validatorNodeAddresses[i] == validatorAddress){
                        isValidatorExist = true;
                        break;
                    }
                }
                if (isValidatorExist == false) {
                    clientInfos[clientAddress].validatorNodeAddresses.push(validatorAddress);
                }

                if (agentAddress!= address(0)){
                    bool isClientExist = false;
                    for (uint256 i = 0;i < client.agentAddresses.length;i++){
                        if (client.agentAddresses[i] == clientAddress){
                            isClientExist = true;
                            break;
                        }
                    }
                    if (isClientExist == false){
                        clientInfos[clientAddress].agentAddresses.push(clientAddress);
                    }
                }
            }
        }

        //////////////////////////// Search ////////////////////////////////////////
        function getValidatorNodeInfo(address nodeAddress) public view returns(NodeInfo memory){
            return validiteNodes[nodeAddress];
        }

        function getAgentInfo(address agentAddress) public view returns(AgentInfo memory) {
            return agentInfos[agentAddress];
        }


        function getClient(address clientAddress) public view returns(ClientInfo memory) {
            return clientInfos[clientAddress];
        }



}