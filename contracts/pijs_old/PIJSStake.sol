// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

struct UserInfo {
    address account;
    uint[] LPStakingAmounts;
    uint[] LPStakingTimes;
    uint[] LPReStakingTimes;
    uint[] LPStakingLockTimes;
    uint[] LPStakingIds;
    uint[] LPStakingStatus; // 0 -staking; 1- unstaking
    uint[] PIJSStakingTypes;
    uint[] PIJSStakingNums;
    uint[] PIJSStakingAmounts;
    uint[] PIJSStakingTimes;
    uint[] PIJSReStakingTimes;
    uint[] PIJSStakingLockTimes;
    uint[] PIJSStakingIds;
    uint[] PIJSStakingStatus; // 0 -staking; 1- unstaking
}

contract PIJSStake is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");

    bool private funcSwitch;

    IERC20Upgradeable private LPToken;
    mapping(address => UserInfo) private userInfos;

    mapping(uint => uint) public PIJSStakeTypeNumber;
    mapping(uint => uint) public PIJSStakeTypeSoldNumber;

    event StakingPIJS(
        address caller,
        uint stakeType,
        uint stakeNum,
        uint stakeAmount,
        uint stakeId
    );

    event ReStakingPIJS(address caller, uint stakingId, uint reStaingTime);

    event UnstakingPIJS(address caller, uint stakingId, uint amount);

    event StakingLP(
        address caller,
        uint amount,
        uint stakingTime,
        uint stakingLockTime,
        uint stakingId
    );

    event ReStakingLP(address caller, uint stakingId, uint reStaingTime);

    event UnstakingLP(address caller, uint stakingId, uint amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(IERC20Upgradeable _LPToken) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);

        LPToken = _LPToken;

        PIJSStakeTypeNumber[30 days] = 1000;
        PIJSStakeTypeNumber[60 days] = 1000;
        PIJSStakeTypeNumber[90 days] = 1000;

        ///@notice for test
        // PIJSStakeTypeNumber[30 minutes] = 1000;
        // PIJSStakeTypeNumber[60 minutes] = 1000;
        // PIJSStakeTypeNumber[90 minutes] = 1000;
    }

    receive() external payable {}

    // function reSet() public onlyRole(MANAGE_ROLE) {
    //     ///@notice for test
    //     PIJSStakeTypeNumber[30 minutes] = 1000;
    //     PIJSStakeTypeNumber[60 minutes] = 1000;
    //     PIJSStakeTypeNumber[90 minutes] = 1000;
    // }

    function balance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function setFuncSwith(bool _funcSwitch) public onlyRole(MANAGE_ROLE) {
        funcSwitch = _funcSwitch;
    }

    function stakePIJS(
        uint stakeType,
        uint stakeNum
    ) public payable nonReentrant {
        UserInfo storage userInfo = userInfos[msg.sender];
        require(
            PIJSStakeTypeNumber[stakeType] > 0,
            "PIJSStake: stakeType error"
        );
        require(
            (PIJSStakeTypeSoldNumber[stakeType] + stakeNum) <=
                PIJSStakeTypeNumber[stakeType],
            "PIJSStake: stakeNum error"
        );
        ///@notice for test
        //uint stakeAmount = stakeNum * 5000 * 1e18;
        uint stakeAmount = stakeNum * 5 * 1e18;
        require(msg.value == stakeAmount, "PIJSStake: value error");
        if (userInfo.account == address(0)) {
            userInfo.account = msg.sender;
        }
        PIJSStakeTypeSoldNumber[stakeType] += stakeNum;
        userInfo.PIJSStakingTypes.push(stakeType);
        userInfo.PIJSStakingNums.push(stakeNum);
        userInfo.PIJSStakingAmounts.push(stakeAmount);
        userInfo.PIJSStakingTimes.push(block.timestamp);
        userInfo.PIJSStakingLockTimes.push(stakeType);
        userInfo.PIJSStakingIds.push(userInfo.PIJSStakingTypes.length - 1);
        userInfo.PIJSStakingStatus.push(0);
        emit StakingPIJS(
            msg.sender,
            stakeType,
            stakeNum,
            stakeAmount,
            userInfo.PIJSStakingTypes.length - 1
        );
    }

    function reStakePIJS(uint stakingId) public nonReentrant {
        UserInfo storage userInfo = userInfos[msg.sender];
        require(userInfo.PIJSStakingStatus[stakingId] == 0, "PIJS: no staking");
        if (userInfo.PIJSReStakingTimes[stakingId] > 0) {
            require(
                (userInfo.PIJSReStakingTimes[stakingId] +
                    userInfo.PIJSStakingLockTimes[stakingId]) <= block.timestamp
            );
        } else {
            require(
                (userInfo.PIJSStakingTimes[stakingId] +
                    userInfo.PIJSStakingLockTimes[stakingId]) <= block.timestamp
            );
        }
        userInfo.PIJSReStakingTimes[stakingId] = block.timestamp;
        emit ReStakingPIJS(msg.sender, stakingId, block.timestamp);
    }

    function unstakePIJS(uint stakingId) public nonReentrant {
        UserInfo storage userInfo = userInfos[msg.sender];
        require(userInfo.PIJSStakingStatus[stakingId] == 0, "PIJS: no staking");
        if (userInfo.PIJSReStakingTimes[stakingId] > 0) {
            require(
                (userInfo.PIJSReStakingTimes[stakingId] +
                    userInfo.PIJSStakingLockTimes[stakingId]) <= block.timestamp
            );
        } else {
            require(
                (userInfo.PIJSStakingTimes[stakingId] +
                    userInfo.PIJSStakingLockTimes[stakingId]) <= block.timestamp
            );
        }
        userInfo.PIJSStakingStatus[stakingId] = 1;
        require(
            userInfo.PIJSStakingAmounts[stakingId] > 0,
            "PIJSStaking: no staking"
        );
        payable(msg.sender).transfer(userInfo.PIJSStakingAmounts[stakingId]);

        emit UnstakingPIJS(
            msg.sender,
            stakingId,
            userInfo.PIJSStakingAmounts[stakingId]
        );
    }

    function stakeLP(uint amount, uint time) public nonReentrant {
        require(amount > 0, "PIJSStake: amount error");
        require(
            time == 0 || time == 7 days || time == 15 days || time == 30 days,
            "PIJSStake: time error"
        );
        ///@notice for test
        // require(
        //     time == 0 ||
        //         time == 7 minutes ||
        //         time == 15 minutes ||
        //         time == 30 minutes,
        //     "PIJSStake: time error"
        // );
        UserInfo storage userInfo = userInfos[msg.sender];
        if (userInfo.account == address(0)) {
            userInfo.account = msg.sender;
        }
        LPToken.safeTransferFrom(msg.sender, address(this), amount);
        userInfo.LPStakingAmounts.push(amount);
        userInfo.LPStakingTimes.push(block.timestamp);
        userInfo.LPReStakingTimes.push(0);
        userInfo.LPStakingLockTimes.push(time);
        userInfo.LPStakingIds.push(userInfo.LPStakingAmounts.length - 1);
        userInfo.LPStakingStatus.push(0);
        emit StakingLP(
            msg.sender,
            amount,
            block.timestamp,
            time,
            userInfo.LPStakingAmounts.length - 1
        );
    }

    function reStakeLP(uint stakingId) public nonReentrant {
        UserInfo storage userInfo = userInfos[msg.sender];
        require(userInfo.LPStakingStatus[stakingId] == 0, "PIJS: no staking");
        // commit for test
        
        if (userInfo.LPReStakingTimes[stakingId] > 0) {
            require(
                (userInfo.LPReStakingTimes[stakingId] +
                    userInfo.LPStakingLockTimes[stakingId]) <= block.timestamp
            );
        } else {
            require(
                (userInfo.LPStakingTimes[stakingId] +
                    userInfo.LPStakingLockTimes[stakingId]) <= block.timestamp
            );
        }
        userInfo.LPReStakingTimes[stakingId] = block.timestamp;
        emit ReStakingLP(msg.sender, stakingId, block.timestamp);
    }

    function unstakeLP(uint stakingId) public nonReentrant {
        UserInfo storage userInfo = userInfos[msg.sender];
        require(userInfo.LPStakingStatus[stakingId] == 0, "PIJS: no staking");
        if (userInfo.LPReStakingTimes[stakingId] > 0) {
            require(
                (userInfo.LPReStakingTimes[stakingId] +
                    userInfo.LPStakingLockTimes[stakingId]) <= block.timestamp
            );
        } else {
            require(
                (userInfo.LPStakingTimes[stakingId] +
                    userInfo.LPStakingLockTimes[stakingId]) <= block.timestamp
            );
        }
        userInfo.LPStakingStatus[stakingId] = 1;
        require(
            userInfo.LPStakingAmounts[stakingId] > 0,
            "PIJSStaking: no staking"
        );

        LPToken.safeTransfer(msg.sender, userInfo.LPStakingAmounts[stakingId]);

        emit UnstakingLP(
            msg.sender,
            stakingId,
            userInfo.LPStakingAmounts[stakingId]
        );
    }
    ///////////////////////////////////////////////////////////   V2
    bytes32 private constant STAKELP_PERMIT_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(address caller,uint256 lpFakeOrderId,uint256 productId,uint256 purchaseNum,uint256 round,uint256 lpAmount,uint256 lpValue,uint256 lpStartTimeStamp,uint256 lpEndTimeStamp,uint256 pledgeDays,uint256 lockTimeStamp,uint256 chainId)"
        )
    );
    event StakeLPV2(address caller,uint256 lpFakeOrderId,uint256 productId,uint256 purchaseNum,uint256 round,uint256 lpAmount,uint256 lpValue,uint256 lpStartTimeStamp,uint256 lpEndTimeStamp,uint256 pledgeDays,uint256 stakeId);
    function getDOMAIN_SEPARATOR() internal view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("PIJSStake")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }
    address private signer;
    function setSigner(address _signer) public onlyRole(MANAGE_ROLE) {
        signer = _signer;
    }
    function getSigner()public view onlyRole(MANAGE_ROLE) returns(address) {
        return signer;
    }
    
    struct StakeV2Data {
        address caller;
        uint256 lpFakeOrderId;
        uint256 productId;
        uint256 purchaseNum;
        uint256 round;
        uint256 lpAmount;
        uint256 lpValue;
        uint256 lpStartTimeStamp;
        uint256 lpEndTimeStamp;
        uint256 pledgeDays;
        uint256 lockTimeStamp;
        uint256 chainId;
    }
    function stakeLPV2(bytes calldata data) public payable nonReentrant {
        StakeV2Data memory stakeLPV2data = parseStakeLPV2Data(data);
        UserInfo storage userInfo = userInfos[msg.sender];
        if (userInfo.account == address(0)) {
            userInfo.account = msg.sender;
        }
        
        LPToken.safeTransferFrom(msg.sender, address(this), stakeLPV2data.lpAmount);
        userInfo.LPStakingAmounts.push(stakeLPV2data.lpAmount);
        userInfo.LPStakingTimes.push(block.timestamp);
        userInfo.LPReStakingTimes.push(0);
        userInfo.LPStakingLockTimes.push(stakeLPV2data.lockTimeStamp);
        userInfo.LPStakingIds.push(userInfo.LPStakingAmounts.length - 1);
        userInfo.LPStakingStatus.push(0);

        emit StakeLPV2(msg.sender,stakeLPV2data.lpFakeOrderId,stakeLPV2data.productId,stakeLPV2data.purchaseNum,stakeLPV2data.round,stakeLPV2data.lpAmount,stakeLPV2data.lpValue,stakeLPV2data.lpStartTimeStamp,stakeLPV2data.lpEndTimeStamp,stakeLPV2data.pledgeDays,userInfo.LPStakingAmounts.length - 1);
    }
    function parseStakeLPV2Data(bytes calldata data) internal view returns (StakeV2Data memory) {
        (
            address caller,
            uint256 lpFakeOrderId,
            uint256 productId,
            uint256 purchaseNum,
            uint256 round,
            uint256 lpAmount,
            uint256 lpValue,
            uint256 lpStartTimeStamp,
            uint256 lpEndTimeStamp,
            uint256 pledgeDays,
            uint256 lockTimeStamp,
            uint256 chainId,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                address,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                bytes
            )
        );
        require(caller == msg.sender,"PIJSStake:INVALID_USER caller");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        STAKELP_PERMIT_TYPEHASH,
                        caller,
                        lpFakeOrderId,
                        productId,
                        purchaseNum,
                        round,
                        lpAmount,
                        lpValue,
                        lpStartTimeStamp,
                        lpEndTimeStamp,
                        pledgeDays,
                        lockTimeStamp,
                        chainId
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "UnionBridgeSource: INVALID_REQUEST"
        );
        require(lpAmount>0,"PIJSStake:lpAmount shoud not be 0");
        return StakeV2Data({
            caller:caller,
            lpFakeOrderId:lpFakeOrderId,
            productId:productId,
            purchaseNum:purchaseNum,
            round:round,
            lpAmount:lpAmount,
            lpValue:lpValue,
            lpStartTimeStamp:lpStartTimeStamp,
            lpEndTimeStamp:lpEndTimeStamp,
            pledgeDays:pledgeDays,
            lockTimeStamp:lockTimeStamp,
            chainId:chainId
        });

    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "UnionBridgeSource:Not Invalid Signature Data");
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


