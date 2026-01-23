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

INFOErc20 address is: 0x56d0a2a75fA6F733Df20CEb8D7e987134c05C96b

infoWBNBPair address is: 0x8687CfCcc6D4Aa3d3E8d298F069E5eadBa59Bb2A

usdt/wbnb pair address: 0x4dCa7367AAc18865A95545ebD84703C91A6d1609



入金合约：

DepositContract address is: 0x0146e0D7A0d66b03D0658863317a09DC5588c1Ff

入金池：

EcoMineralPool(50%) address is: 0x68a0176956709C57a775afE9Ce34Fe318aedf2B6

TreasuryInsurancePool(35%) address is: 0x7c3EDDc77f37ECec6ea04B6D86c61B90e9deF9c3

S1Pool(10%) address is: 0x228b5959B21E12151A094ee5F985bEd494445298

GenesisNodeDistrictDividendPool(5%) address is: 0x0473b7D0F4eEF4b0f761533040c4e4fe714cd729

奖励领取合约：

INFORewardDistribute address is: 0xDe8eF37E83EBCb08A54D5F663C3C45486960D3D8

签名者（仅测试网使用）：0x98ade8368090031b8a0185383d3dfde4eab076d0



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

### 售出 sellInfo

```
function sellInfo(address tokenAddress,uint256 amount)
```

- tokenAddress INFO代币地址
- amount 售出的数量

事件：

```
 event SellInfo(address userAddr,uint256 infoAmount,uint256 bnbReceived,uint256 addLiquidityAmount,uint256 info2usdtAmount,uint256 userRemainUSDTQuota,uint256 userRemainINFOQuota,uint256 createTime);
   
```

- userAddr  出售者地址
- infoAmount 出售的INFO数量
- bnbReceived 购买到的BNB数量
- addLiquidityAmount 用于添加流动性的INFO数量
-  info2usdtAmount 本次购买扣除的通证数量（USDT）
- userRemainUSDTQuota 本次购买之后剩余的额度（USDT计算）
- userRemainINFOQuota 本次购买之后剩余的额度（INFO计算）
- createTime 创建时间



## 入金池合约

### EcoMineralPool(50%)

#### domain

```
DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("EcoMineralPool")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
```



#### withdrawBNBToReward 提取bnb到奖励合约

方法：

```
function withdrawBNBToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE) nonReentrant
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_BNB =
        keccak256(
            abi.encodePacked(
                "Permit(uint256 amount,uint256 nonce)"
            )
        );

```



```
(
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```

事件：

```
event WithdrawBNBToReward(address userAddr,uint256 amount,address rewardAddress,uint256 createTime);
```



#### withdrawErc20ToReward 提取erc20到奖励合约

方法：

```
function withdrawErc20ToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE)
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_ERC20 =
        keccak256(
            abi.encodePacked(
                "Permit(address token,uint256 amount,uint256 nonce)"
            )
        );
```



```
 (
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```

事件：

```
event WithdrawErc20ToReward(address userAddr,address token,uint256 amount,address rewardAddress,uint256 createTime);
```



### TreasuryInsurancePool(35%)

#### domain

```
 DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("TreasuryInsurancePool")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
```



#### withdrawBNBToReward 提取bnb到奖励合约

方法：

```
function withdrawBNBToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE) nonReentrant
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_BNB =
        keccak256(
            abi.encodePacked(
                "Permit(uint256 amount,uint256 nonce)"
            )
        );

```



```
(
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```

事件：

```
event WithdrawBNBToReward(address userAddr,uint256 amount,address rewardAddress,uint256 createTime);
```



#### withdrawErc20ToReward 提取erc20到奖励合约

方法：

```
function withdrawErc20ToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE)
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_ERC20 =
        keccak256(
            abi.encodePacked(
                "Permit(address token,uint256 amount,uint256 nonce)"
            )
        );
```



```
 (
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```



事件：

```
event WithdrawErc20ToReward(address userAddr,address token,uint256 amount,address rewardAddress,uint256 createTime);
```










#### 回购

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



### S1Pool(10%) 

#### domain

```
DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("S1Pool")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
```



#### withdrawBNBToReward 提取bnb到奖励合约

方法：

```
function withdrawBNBToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE) nonReentrant
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_BNB =
        keccak256(
            abi.encodePacked(
                "Permit(uint256 amount,uint256 nonce)"
            )
        );

```



```
(
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```

事件：

```
event WithdrawBNBToReward(address userAddr,uint256 amount,address rewardAddress,uint256 createTime);
```



#### withdrawErc20ToReward 提取erc20到奖励合约

方法：

```
function withdrawErc20ToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE)
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_ERC20 =
        keccak256(
            abi.encodePacked(
                "Permit(address token,uint256 amount,uint256 nonce)"
            )
        );
```



```
 (
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```



事件：

```
event WithdrawErc20ToReward(address userAddr,address token,uint256 amount,address rewardAddress,uint256 createTime);
```





### GenesisNodeDistrictDividendPool(5%) 

#### domain

```
DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("GenesisNodeDistrictDividendPool")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
```



#### withdrawBNBToReward 提取bnb到奖励合约

方法：

```
function withdrawBNBToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE) nonReentrant
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_BNB =
        keccak256(
            abi.encodePacked(
                "Permit(uint256 amount,uint256 nonce)"
            )
        );

```



```
(
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```



#### withdrawErc20ToReward 提取erc20到奖励合约

方法：

```
function withdrawErc20ToReward(
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE)
```

permit

```
bytes32 private constant PERMIT_TYPEHASH_ERC20 =
        keccak256(
            abi.encodePacked(
                "Permit(address token,uint256 amount,uint256 nonce)"
            )
        );
```



```
 (
            address token,
            uint256 amount,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
                data,
                (address,uint256, uint256, bytes)
            );
```

事件：

```
event WithdrawErc20ToReward(address userAddr,address token,uint256 amount,address rewardAddress,uint256 createTime);
```













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

