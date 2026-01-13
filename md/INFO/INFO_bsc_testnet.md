# 合约地址
测试网USDT:

USDTTest address is: 0x43Db2F7e34F8583b2eEd39681bC77C2699f15A6d

NFT:

AsiaTelevisionINFONFT address is: 0xA3Cb059d4c85164cA63433b5Dd59fE986DFf85F5

推荐合约：

RecommendationINFO address is: 0xe1fE7Ff080f842D6cb25a820FBb2db6F082fa87E

NFT销售合约：

INFONFTSellManage address is: 0x4d25E8a0C8eAaB664aFd9186E2D4B13bc81d1A1c



INFO代币：

INFOErc20 address is: 0x1B9D597997DC0BC1b41786556a48C976866B5B64

infoWBNBPair address is: 0x1D2c55FcD0a7DBf7AB6BF8E69A63eC0BAfd7703C

usdt/wbnb pair address: 0x4dCa7367AAc18865A95545ebD84703C91A6d1609



入金合约：

DepositContract address is: 0xc4f7F567838918610D4481cF875495Da241A352c

入金池：

EcoMineralPool(50%) address is: 0x1375E91522Cbc110d6844c1187610869373D9ca4
TreasuryInsurancePool(35%) address is: 0x886cEFa55C7E8F3F0E07a67Ca0aC841240580002
S1Pool(10%) address is: 0x6eE5B70cf3652678134e6609C98892FDBA2262Dc
GenesisNodeDistrictDividendPool(5%) address is: 0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10

奖励领取合约：

INFORewardDistribute address is: 0xFd5577f62435Cf6c721461B7fE6cF73eBEc754cD

签名者私钥（仅测试网使用）：0x843f834c0bd6cfd7a5253c509e41924b4eb5f0daeeca7bc4bbc28eb1971ef565

0xcdDa4F2ADD39Db9F64Ee43e7A825655e5c865FFd



0 地址：0x000000000000000000000000000000000000dEaD








# ABI

### INFOErc20

#### 卖出事件

```
event SellToken(address token,address from,address to,uint256 amount,uint256 salseQuota,uint256 createTime)
```

- token info代币地址
- from 用户地址
- to info/bnb交易对地址
- amount 卖出INFO的数量
- salseQuota 卖出后用户的额度（INFO非USDT）
- createTime 创建时间



## INFONFTSellManage

### 入参

```
function buyNode(address usdtTokenAddress,uint256 amount,address recommender)
```

### 事件

```
event BuyNode(address user,address recommender,address usdtAddress,uint256 amount,address receiver,address nftAddress,uint256 niftId,uint256 createTime);
```



## RecommendationINFO

### 入参

```
function bindRelationShip(address referrerAddress)
```

### 事件

```
event BindRelationShip(address  user, address referrerAddress,address[] referralChain,uint256 timestamp);
```

user 用户

referrerAddress 推荐人

referralChain 推荐人推荐的地址数组

timestamp 创建时间



## DepositContract入金合约

### 入金 deposit

```
function deposit(address _usdt,uint256 amount,uint256 usdValue)
```

#### 入参

- _usdt usdt合约地址
- amount usdt数量
- usdValue usdt的价值

#### 事件

```
event Deposit(address userAddress,address usdt,uint256 usdtAmount,uint256 bnbAmount,uint256 swapedBnbAmount,address receive0,uint256 infoAmount,address receiver1,uint256 receiver1Amount,address receiver2,uint256 receiver2Amount,address receiver3,uint256 receiver3Amount,uint256 usdValue,uint256 userSalseQuota,uint256 createTime);

```



- userAddress 调用者用户地址

- usdt usdt地址

- usdtAmount usdt的数量

- bnbAmount bnb的数量

- swapedBnbAmount 如果存的是bnb则是传入bnb的数量，如果是usdt则是从swap购买出来的bnb的数量

- receive0 50%买入INFO进入静态分配池(生态矿池)的地址

- infoAmount 50%买入INFO进入静态分配池(生态矿池)的数量

- receiver1 35%进入国库保险池(合约)的地址

- receiver1Amount 35%进入国库保险池(合约)的数量

- receiver2 10% 只有S1级别可拿 (可做实时结)的地址

- receiver2Amount 10% 只有S1级别可拿 (可做实时结)的数量

- receiver3    5% 创世节点小区加权分红的合约地址

- receiver3Amount   5% 创世节点小区加权分红的数量

- usdValue usdt的价值

- userSalseQuota 入金后当前卖出INFO的usdt额度

- createTime 创建时间

  





### 获取可卖的INFO代币的usdt价值额度 getSalseQuotaUSDT

```
function getSalseQuotaUSDT(address user)
```

- User 用户地址

### 获取可卖的INFO代币的额度 getSalseQuotaINFO

```
function getSalseQuotaINFO(address user) 
```

- User 用户地址

### 获取INFO的usdt价格

```
function getInfo2USDT(uint256 infoAmount) public view returns(uint256) 
```



### 获取usdt兑换INFO的数量

```
 function getbnb2USDT(uint256 amount) public view returns(uint256)
```

### 获取bnb兑换INFO

```
function getbnb2USDT(uint256 amount) public view returns(uint256)
```

### 获取bnb兑换USDT

```
function getbnb2USDT(uint256 amount) public view returns(uint256)
```





## 入金池合约

EcoMineralPool(50%) address is: 0x1375E91522Cbc110d6844c1187610869373D9ca4
TreasuryInsurancePool(35%) address is: 0xc36268C3Fe6d574A329Ec0676031b6dFe407a7e2
S1Pool(10%) address is: 0x6eE5B70cf3652678134e6609C98892FDBA2262Dc
GenesisNodeDistrictDividendPool(5%) address is: 0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10

### withdrawErc20

#### 入参

```
function withdrawErc20(
        address token,
        address to,
        uint256 amount
    ) public onlyRole(MANAGE_ROLE) 
```

- token 要提取的token地址
- to 转移的地址
- amount 数量

#### 事件

```
event WithdrawErc20(address token,address operator,address to,uint256 amount,uint256 createTime);
```



- token erc20地址
- operator 操作人地址
- amount erc20的数量
- createTime 创建时间



### withdrawBNB

#### 入参

```
function withdrawBNB(
        address to,
        uint256 amount
    )
```

#### 事件

```
WithdrawBNB(address operator,address to,uint256 amount,uint256 createTime)
```



### balance 查询合约余额

```
function balance(address token) public view returns (uint256)
```

- Token erc20地址，  返回数量，本币传0地址



## TreasuryInsurancePool

### 回购

```
function redeem() 
```



```
event Redeem(address operator,uint256 bnbBalance,uint256 redeemAmount,uint256 createTime);
```

- operator 操作人地址
- bnbBalance 回购前合约内bnb余额
- redeemAmount 回购的数量
- createTime 创建时间



## 奖励领取合约 INFORewardDistribute

### withdrawReward

#### 入参

```
 function withdrawReward(bytes memory data) public nonReentrant 
```

```
require(!funSwitch, "ERROR: NOT SERVICES");
        (
            address user,
            address token,
            uint256 order,
            uint256 amount,
            uint256 nonce,
            uint256 deadline,
            bytes memory signature
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, bytes)
            );
```

- user 用户地址
- token erc20地址
- order 订单id
- amount 领取数量
- nonce 
- deadline

#### domain

```
DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("INFORewardDistribute")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
```



#### permit

```
bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Permit(address user,address token,uint256 order,uint256 amount,uint256 nonce,uint256 deadline)"
            )
        );

```



#### 事件

```
   event WithdrawReward(
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 timestamp,
        uint256 order,
        uint256 rewardType
    );
```

