// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IPIJSPair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function token0() external view returns (address);

    function totalSupply() external view returns (uint);
}

contract PIJSPool is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    IERC20Upgradeable private LPToken;

    IERC20Upgradeable private WPIJS;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(
        IERC20Upgradeable _LPToken,
        IERC20Upgradeable _WPIJS
    ) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);

        LPToken = _LPToken;
        WPIJS = _WPIJS;
    }

    function balance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function queryPIJSAmount(
        uint usdtAmount
    ) public view returns (uint PIJSAmount) {
        address token0 = IPIJSPair(address(LPToken)).token0();
        (uint112 reserve0, uint112 reserve1, ) = IPIJSPair(address(LPToken))
            .getReserves();
        if (token0 == address(WPIJS)) {
            PIJSAmount = (usdtAmount * uint256(reserve1)) / uint256(reserve0);
        } else {
            PIJSAmount = (usdtAmount * uint256(reserve0)) / uint256(reserve1);
        }
    }

    function queryLPTokenAmount(
        uint usdtAmount
    ) public view returns (uint LPTokenAmount) {
        uint LPTokenTotalSupply = IPIJSPair(address(LPToken)).totalSupply();
        address token0 = IPIJSPair(address(LPToken)).token0();
        (uint112 reserve0, uint112 reserve1, ) = IPIJSPair(address(LPToken))
            .getReserves();
        if (token0 == address(WPIJS)) {
            LPTokenAmount =
                (LPTokenTotalSupply * usdtAmount) /
                (2 * uint(reserve1));
        } else {
            LPTokenAmount =
                (LPTokenTotalSupply * usdtAmount) /
                (2 * uint(reserve0));
        }
    }
}
