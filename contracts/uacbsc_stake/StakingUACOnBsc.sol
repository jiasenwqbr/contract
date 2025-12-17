// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
library SafeMath {
    function mul(uint a,uint b) internal pure returns (uint){
        if (a == 0){
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint a,uint b) internal pure returns (uint) {
        uint c = a/b;
        return c; 
    }
    function sub(uint a,uint b) internal pure returns (uint){
        assert(b <= a);
        return a - b;
    }
    function add(uint a,uint b) internal pure returns (uint){
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract StakingUACOnBsc is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint;
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    bool private funcSwitch;
    // for tentation
    uint256 public constant SECONDS_PER_DAY = 60 * 60;
    // uint256 public constant SECONDS_PER_DAY = 86400;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(address _uac) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        uac = _uac;
        funcSwitch = true;
        rewardPerDay = 10000 ether;
    }

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    /////////////////////////////////////////////////////////////*/
    address uac;
    uint256 public rewardPerDay;
    uint256 public totalStaked; //当前质押总量
    struct UserInfo {
        uint256 amount;          // 当前质押量
        uint256 rewardBalance;      // 奖励
        uint256 lastCalRewardTime;  // 上次计算奖励时间
        uint256 fristStakeTime;  // 首次质押时间
        uint256 rewardReceived;  // 已领取奖励
    }
    mapping(address => UserInfo) public users;
    mapping(uint256 => uint256) totalStakePerDay; // 每天的质押总量，只用变化才会存储
    uint256[] perdays; // 总量变化的日期
    mapping(address => mapping(uint256 => uint256)) userTotalStakePerDay; //用户每天的质押总量，只有变化才会存储
    mapping(address => uint256[]) userPerDays;// 用户总量变化的日期


    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event Stake(address userAddress,uint256 amount,uint256 userTotalAmount,uint256 total,uint256 createTime);
    event UnStake(address userAddress,uint256 amount,uint256 userTotalAmount,uint256 total,uint256 createTime);
    event CalculateReward(address userAddress,uint256 calculateDays,uint256 calculateStartTime,uint256 lastCalRewardTime);
    event WithDrawReward(address userAddress,address tokenAddress,uint256 amount,uint256 createTime);
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /* ===================== 用户操作 ===================== */

    // 增加质押
    function stake(uint256 amount,address tokenAddress) external nonReentrant {
        require(amount > 0, "amount=0");
        require(tokenAddress == uac,"token address error");

        IERC20(uac).transferFrom(msg.sender, address(this), amount);
        // 更新用户质押总量
        uint256 userAmount = users[msg.sender].amount.add(amount);
        // 更新全网总量
        totalStaked = totalStaked.add(amount);
        // 当天日期
        if (users[msg.sender].fristStakeTime == 0){
            users[msg.sender].fristStakeTime = block.timestamp;
        }
        _updateTotalAmountPerDay(userAmount,totalStaked);
        emit Stake(msg.sender,amount,users[msg.sender].amount,totalStaked,block.timestamp);
    }
    // 减少质押，撤本金
    function unStake(uint256 amount,address tokenAddress) external nonReentrant {
        require(amount > 0, "amount=0");
        require(tokenAddress == uac,"token address error");
        require(users[msg.sender].amount >= amount,"not enough amount");

        IERC20(uac).transfer(msg.sender,amount);
        uint256 userAmount = users[msg.sender].amount.sub(amount);
        // 更新全网总量
        totalStaked = totalStaked.sub(amount);
        _updateTotalAmountPerDay(userAmount,totalStaked);
        emit UnStake(msg.sender,amount,users[msg.sender].amount,totalStaked,block.timestamp);  
    }

    function _updateTotalAmountPerDay(uint256 userAmount,uint256 totalAmount) internal {
        // 更新用户质押总量
        users[msg.sender].amount = userAmount;
         // 当天日期
        uint256 dayIndex = getDayIndex(block.timestamp);
        // 更新用户当天总量
        userTotalStakePerDay[msg.sender][dayIndex] =  userAmount;
        if (!isUserExistDay(dayIndex,msg.sender)){
            userPerDays[msg.sender].push(dayIndex);
        }
        // 更新全网当天总量
        totalStakePerDay[dayIndex] = totalAmount;
        if (!isExistDay(dayIndex)){
            perdays.push(dayIndex);
        }
    }

    // 计算奖励
    function calculateReward() external nonReentrant {
        // 判断用户有多少天未计算奖励
        UserInfo memory user = users[msg.sender];
        require(user.fristStakeTime != 0,"user have not staked");
        uint256 todayIndex = getDayIndex(block.timestamp);
        uint256 calculateTime;
        if (user.lastCalRewardTime == 0){
            calculateTime = user.fristStakeTime;
        } else {
            calculateTime = user.lastCalRewardTime;
        }
        uint256 calculateTimeDayIndex = getDayIndex(calculateTime);
        require(calculateTimeDayIndex < todayIndex,"No reward generated");
        uint256 calculateDays = todayIndex.sub(calculateTimeDayIndex);
        uint256 benfit;
        for (uint256 i = 0;i < calculateDays;i++){
            // 计算日的总量
            uint256 currentDayTotal = getCurrentTotal(calculateTimeDayIndex.add(i));
            // 计算日用户的质押总量
            uint256 currentDayUserTotal = getCurrentDayUserTotal(calculateTimeDayIndex.add(i),msg.sender);
            // 计算日的用户收益
            uint256 currentBenfit = currentDayUserTotal.mul(rewardPerDay).div(currentDayTotal);
            benfit = benfit + currentBenfit;
        }
        users[msg.sender].rewardBalance = users[msg.sender].rewardBalance.add(benfit);
        users[msg.sender].lastCalRewardTime = block.timestamp;
        
        emit CalculateReward(msg.sender,calculateDays,calculateTime,block.timestamp);

    }

    // 领取奖励
    function withDrawReward(address tokenAddress,uint256 amount) external nonReentrant  {
        require(funcSwitch,"the func is closed");
        require(amount > 0, "amount=0");
        require(tokenAddress == uac,"token address error");
        UserInfo memory user = users[msg.sender];
        require(user.rewardBalance >= amount,"not enough to with draw");
        // 转账
        IERC20(uac).transfer(msg.sender,amount);
        // 更新用户状态
        users[msg.sender].rewardBalance = users[msg.sender].rewardBalance.sub(amount);
        users[msg.sender].rewardReceived = users[msg.sender].rewardReceived.add(amount);
        emit WithDrawReward(msg.sender,tokenAddress,amount,block.timestamp);
    }

    // 判断当天是否存在
    function isExistDay(uint256 today) internal view returns(bool) {
        bool flag = false;
        for (uint256 i = 0; i< perdays.length;i++){
            if (perdays[i] == today){
                flag = true;
                break;
            }
        }
        return flag;
    }
    function isUserExistDay(uint256 today,address userAddr) internal view returns(bool) {
        bool flag = false;
        for (uint256 i = 0; i< userPerDays[userAddr].length;i++){
            if (perdays[i] == today){
                flag = true;
                break;
            }
        }
        return flag;
    }

    function getDayIndex(uint256 timePerSecond) public pure returns (uint256) {
        return timePerSecond / SECONDS_PER_DAY;
    }

    function getCurrentTotal(uint256 dayIndex) internal view returns(uint256) {
        uint256 currentDayTotal = totalStakePerDay[dayIndex];
        if (currentDayTotal == 0){
            // 寻找计算日小的最近的日
            (uint256 closerDay,bool found) =  findClosestSmaller(perdays,dayIndex);
            require(found,"total can not be found");
            currentDayTotal =  totalStakePerDay[closerDay];
        }
        return currentDayTotal;
    }

    function getCurrentDayUserTotal(uint256 dayIndex,address userAddr) internal view returns(uint256){
        uint256 currentUserDayTotal = userTotalStakePerDay[userAddr][dayIndex];
        if (currentUserDayTotal == 0){
            (uint256 closerDay,bool found) =  findClosestSmaller(userPerDays[userAddr],dayIndex);
            require(found,"total can not be found");
            currentUserDayTotal = userTotalStakePerDay[userAddr][closerDay];
        }
        return currentUserDayTotal;
    }

    function findClosestSmaller(
        uint256[] memory arr,
        uint256 x
    ) public pure returns (uint256 result, bool found) {
        uint256 bestDiff = type(uint256).max;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] < x) {
                uint256 diff = x - arr[i];
                if (diff < bestDiff) {
                    bestDiff = diff;
                    result = arr[i];
                    found = true;
                }
            }
        }
    }

    function getMyInfo() public view returns(UserInfo memory) {
        return users[msg.sender];
    }

    function setRewardPerDay(uint256 _reward) public onlyRole(OPERATE_ROLE) {
        rewardPerDay = _reward;
    }

    function getPage( uint256[] storage arr,uint256 offset, uint256 limit) internal view returns (uint256[] memory result) {
        require(limit <= 1000,"limit must less than 1000");
        uint256 length = arr.length;
        if (offset >= length) {
            return new uint256[](0);
        }

        uint256 end = offset + limit;
        if (end > length) {
            end = length;
        }

        result = new uint256[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = arr[i];
        }
    }

    function getPerDays(uint256 offset,uint256 limit) public view returns(uint256[] memory result){
        return getPage(perdays,offset,limit);
    }
    function getUserPerDays(address userAddr,uint256 offset,uint256 limit) public view returns(uint256[] memory result){
        return getPage(userPerDays[userAddr],offset,limit);
    }

    function getTotalStakePerDay(uint256 dayIndex) public view returns(uint256){
        return  getCurrentTotal(dayIndex) ;
    }
    function getUserTotalStakePerDay(uint256 dayIndex,address userAddr) public view returns(uint256){
        return getCurrentDayUserTotal(dayIndex,userAddr);
    }

}