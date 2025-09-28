// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Airdrop is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    IERC20Upgradeable private usdt;

    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(address operator) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        _grantRole(OPERATE_ROLE, operator);
    }

    receive() external payable {}

    function airdrop(
        address token,
        address[] calldata adds,
        uint[] calldata amounts
    ) public  onlyRole(OPERATE_ROLE) {
        require(adds.length == amounts.length, "length error");
        for (uint i = 0; i < adds.length; i++) {
            IERC20Upgradeable(token).safeTransfer(adds[i], amounts[i]);
        }
    }

    function airdropBnb(
        address[] calldata adds,
        uint[] calldata amounts
    ) public onlyRole(OPERATE_ROLE) {
        require(adds.length == amounts.length, "length error");
        for (uint i = 0; i < adds.length; i++) {
            payable(adds[i]).transfer(amounts[i]);
        }
    }
}
