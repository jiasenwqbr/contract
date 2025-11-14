// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

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
         constructor() {
            _disableInitializers(); // 禁止逻辑合约自己初始化
        }
        
        function _authorizeUpgrade(
            address newImplementation
        ) internal override onlyRole(MANAGE_ROLE) {}

        /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
        /////////////////////////////////////////////////////////////*/


         /*//////////////////////////////////////////////////////////////
                                 EVENTS
        //////////////////////////////////////////////////////////////*/

        /*//////////////////////////////////////////////////////////////
                               MODIFIERS
        //////////////////////////////////////////////////////////////*/


        /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
        //////////////////////////////////////////////////////////////*/




    }