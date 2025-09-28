// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PIJSLock is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");

    IERC20Upgradeable private PIJS;
    address private foundation;
    uint public releaseAmount;
    uint public currentUnlockTime;
    uint public unlockTimeInterval;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(
        address _foundation,
        address operator
    ) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        _grantRole(OPERATE_ROLE, operator);

        foundation = _foundation;

        ///@notice for for test
        releaseAmount = uint(100 * 1e18) / 24;
        currentUnlockTime = 0;
        unlockTimeInterval = 5 minutes;
    }

    receive() external payable {
        bool role = hasRole(OPERATE_ROLE, msg.sender);
        if (role) {
            if (msg.value == 1 * 1e14) {
                _distribute();
            } else if (msg.value == 2 * 1e14) {
                require(currentUnlockTime == 0, "Lock: already set");
                currentUnlockTime = block.timestamp;
            }
        }
    }

    function balance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function setFoundation(address _foundation) public onlyRole(MANAGE_ROLE) {
        foundation = _foundation;
    }

    // function distribute() public onlyRole(OPERATE_ROLE) {
    //     _distribute();
    // }

    function _distribute() public {
        require(currentUnlockTime != 0, "Lock: time error");
        require(foundation != address(0), "Lock: Zero address error");
        require(
            block.timestamp >= (currentUnlockTime + unlockTimeInterval),
            "Lock: Release time has not come yet"
        );
        uint times = (block.timestamp - currentUnlockTime) / unlockTimeInterval;
        uint _releaseAmount = times * releaseAmount;
        currentUnlockTime += times * unlockTimeInterval;
        if (balance(address(0)) >= _releaseAmount) {
            payable(foundation).transfer(_releaseAmount);
        } else {
            payable(foundation).transfer(balance(address(0)));
        }
    }
}
