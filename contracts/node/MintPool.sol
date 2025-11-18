// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MintPool is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {

     /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }
    
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    receive() external payable {}
    address public poolContract;
    address public operator;
    address public kmsAddress;
    address public to;

    event WithDraw(address from,address to,address erc20Address,uint256 amount,address operator,uint256 createTime);

    function initialize(address _operator,address _to) public initializer {
        operator = _operator;
        to = _to;
         __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        _grantRole(OPERATE_ROLE,_operator);
    }

    function withDraw(address erc20Address,uint256 amount) public onlyRole(OPERATE_ROLE) {
        require(to != address(0),"0 address");
        require(amount > 0,"0 amount");
        require(
           IERC20(erc20Address).transfer(to, amount),
            "MintPool:Payment transfer failed"
        );
        emit WithDraw(address(this),to,erc20Address,amount,operator,block.timestamp);
    }





}