// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

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

contract StakeUACOnBscUpgradeble is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    bool private funcSwitch;
    // for tentation
    // uint256 public constant SECONDS_PER_DAY = 5 * 60;
    uint256 public constant SECONDS_PER_DAY = 86400;
    // constructor(address _uac,address _nftAddress) {
    //     _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    //     _grantRole(MANAGE_ROLE, msg.sender);
    //     _grantRole(OPERATE_ROLE, msg.sender);
    //     uac = _uac;
    //     funcSwitch = true;
    //     rewardPerDay = 10000 ether;
    //     nftAddress = _nftAddress;
    //     stakeMax = 5;
    //     unStakeMax = 5;

    // }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}

    function initialize(address _uac,address _nftAddress) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        _grantRole(OPERATE_ROLE, msg.sender);
         uac = _uac;
        funcSwitch = true;
        rewardPerDay = 20000 ether;
        nftAddress = _nftAddress;
        stakeMax = 100;
        unStakeMax = 100;
    }

   

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    /////////////////////////////////////////////////////////////*/
    address uac;
    address nftAddress;
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
    // 用户地址 => 质押的 NFT ID 集合
    mapping(address => EnumerableSet.UintSet) private _stakedNFTs;
    uint256  public stakeMax;
    uint256  public unStakeMax;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event Stake(address userAddress,uint256 tokenId,uint256 userTotalAmount,uint256 total,uint256 stakedTime,uint256 createTime);
    event UnStake(address userAddress,uint256 amount,uint256 userTotalAmount,uint256 total,uint256 unStakedTime,uint256 createTime);
    event CalculateReward(address userAddress,uint256 calculateDays,uint256 calculateStartTime,uint256 lastCalRewardTime);
    event WithDrawReward(address userAddress,address tokenAddress,uint256 amount,uint256 createTime);
    event StakeBatch(address userAddress,uint256[] tokenIds,uint256 amount,uint256 totalStaked,uint256 stakedTime,uint256 createTime);
    event UnStakeBatch(address userAddress,uint256[] tokenIds,uint256 amount,uint256 totalStaked,uint256 unstakedTime,uint256 createTime);

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /* ===================== 用户操作 ===================== */

    // 增加质押
    function stake(uint256 tokenId,address tokenAddress) external nonReentrant {
        uint256 currentTime = block.timestamp;
        require(tokenId > 0, "amount=0");
        require(tokenAddress == nftAddress,"token address error");
        // require(IERC721(uac).allowance(msg.sender,address(this)) >= amount,"Not enough allowance");
        require(_stakedNFTs[msg.sender].contains(tokenId) == false, "staked by user");

        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        // 更新用户质押总量
        uint256 userAmount = users[msg.sender].amount.add(1);
        // 更新全网总量
        totalStaked = totalStaked.add(1);
        // 当天日期
        if (users[msg.sender].fristStakeTime == 0){
            users[msg.sender].fristStakeTime = currentTime;
        }
        _updateTotalAmountPerDay(userAmount,totalStaked,currentTime);
        // 记录质押信息
        _stakedNFTs[msg.sender].add(tokenId);

        emit Stake(msg.sender,tokenId,users[msg.sender].amount,totalStaked,currentTime,block.timestamp);
    }
    function stakeBatch(uint256[] memory tokenIds,address tokenAddress) external nonReentrant {
        uint256 currentTime = block.timestamp;
        require(tokenIds.length > 0, "amount=0");
        require(tokenIds.length <= stakeMax, "amount>stakeMax");
        require(tokenAddress == nftAddress,"token address error");
        // require(IERC721(uac).allowance(msg.sender,address(this)) >= amount,"Not enough allowance");
       
        for (uint256 i =0;i < tokenIds.length;i++){
            require(_stakedNFTs[msg.sender].contains(tokenIds[i]) == false, "staked by user");
            IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            // 记录质押信息
            _stakedNFTs[msg.sender].add(tokenIds[i]);
        }
        // 更新用户质押总量
        uint256 userAmount = users[msg.sender].amount.add(tokenIds.length);
        // 更新全网总量
        totalStaked = totalStaked.add(tokenIds.length);
        // 当天日期
        if (users[msg.sender].fristStakeTime == 0){
            users[msg.sender].fristStakeTime = currentTime;
        }
        _updateTotalAmountPerDay(userAmount,totalStaked,currentTime);
        emit StakeBatch(msg.sender,tokenIds,users[msg.sender].amount,totalStaked,currentTime,block.timestamp);
    }
    // 减少质押，撤本金
    function unStake(uint256 tokenId,address tokenAddress) external nonReentrant {
        uint256 currentTime = block.timestamp;
        require(_stakedNFTs[msg.sender].contains(tokenId), "Not staked by user");
        require(tokenId > 0, "amount=0");
        require(tokenAddress == nftAddress,"token address error");
        IERC721(nftAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        uint256 userAmount = users[msg.sender].amount.sub(1);
        // 更新全网总量
        totalStaked = totalStaked.sub(1);
        _updateTotalAmountPerDay(userAmount,totalStaked,currentTime);
        // 删除质押记录
        _stakedNFTs[msg.sender].remove(tokenId);

        emit UnStake(msg.sender,tokenId,users[msg.sender].amount,totalStaked,currentTime,block.timestamp);  
    }

    function unStakeBatch(uint256[] memory tokenIds,address tokenAddress) external nonReentrant {
        uint256 currentTime = block.timestamp;
        require(tokenIds.length <= unStakeMax, "amount>unStakeMax");
        require(tokenIds.length > 0, "amount=0");
        require(tokenAddress == nftAddress,"token address error");
        for (uint256 i = 0;i < tokenIds.length;i++){
            require(_stakedNFTs[msg.sender].contains(tokenIds[i]), "Not staked by user");
            IERC721(nftAddress).safeTransferFrom(address(this),msg.sender,tokenIds[i]);
            // 删除质押记录
            _stakedNFTs[msg.sender].remove(tokenIds[i]);
        }
        uint256 userAmount = users[msg.sender].amount.sub(tokenIds.length);
        // 更新全网总量
        totalStaked = totalStaked.sub(tokenIds.length);
        _updateTotalAmountPerDay(userAmount,totalStaked,currentTime);
        emit UnStakeBatch(msg.sender,tokenIds,users[msg.sender].amount,totalStaked,currentTime,block.timestamp);  
    }


    function _updateTotalAmountPerDay(uint256 userAmount,uint256 totalAmount,uint256 currentTime) internal {
        // 更新用户质押总量
        users[msg.sender].amount = userAmount;
         // 当天日期
        uint256 dayIndex = getDayIndex(currentTime);
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
        uint256 currentTime = block.timestamp;
        // 判断用户有多少天未计算奖励
        UserInfo memory user = users[msg.sender];
        require(user.fristStakeTime != 0,"user have not staked");
        uint256 todayIndex = getDayIndex(currentTime);
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
        users[msg.sender].lastCalRewardTime = currentTime;
        
        emit CalculateReward(msg.sender,calculateDays,currentTime,block.timestamp);

    }

    // 领取奖励
    function withDrawReward(address tokenAddress,uint256 amount) external nonReentrant  {
        require(funcSwitch,"the func is closed");
        require(amount > 0, "amount=0");
        require(tokenAddress == uac,"token address error");
        UserInfo memory user = users[msg.sender];
        require(user.rewardBalance >= amount,"not enough to with draw");
        require(IERC20(uac).balanceOf(address(this)) > amount,"not enough to with draw in pool");
        // 转账
        IERC20(uac).safeTransfer(msg.sender,amount);
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
            if (userPerDays[userAddr][i] == today){
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

    function findClosestSmaller( uint256[] memory arr,  uint256 x) public pure returns (uint256 result, bool found) {
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

    function findClosestSmallerBinarySearch(
        uint256[] memory arr,
        uint256 x
    ) public pure returns (uint256 result, bool found) {
        uint256 left = 0;
        uint256 right = arr.length;

        while (left < right) {
            uint256 mid = (left + right) >> 1;
            if (arr[mid] < x) {
                result = arr[mid];
                found = true;
                left = mid + 1;
            } else {
                right = mid;
            }
        }
    }
    
    // 获取我的信息
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

    function withdrawBNB(
        address to,
        uint256 amount
    ) public onlyRole(MANAGE_ROLE) {
        uint256 bnbBalance = payable(address(this)).balance;
        require(bnbBalance >= amount, "ERROR:INSUFFICIENT");
        payable(to).transfer(amount);
    }

    /// @notice 查看用户质押 NFT
    /// @param user 用户地址
    /// @return tokenIds 用户质押的 NFT ID 数组
    function stakedTokens(address user) external view returns (uint256[] memory tokenIds) {
        uint256 length = _stakedNFTs[user].length();
        tokenIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _stakedNFTs[user].at(i);
        }
    }

    function setStakePara(uint256 _stakeMax,uint256 _unStakeMax) public onlyRole(MANAGE_ROLE) {
        stakeMax = _stakeMax;
        unStakeMax = _unStakeMax;
    }

    function onERC721Received( address, address, uint256, bytes calldata) external pure  returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setNftAddress(address nft_addreess)  public onlyRole(MANAGE_ROLE) {
        nftAddress = nft_addreess;
    }

    function getNftAddress() public view  returns(address){
        return nftAddress ;
    }

}