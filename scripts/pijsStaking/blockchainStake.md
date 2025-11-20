# 公链质押

## ValidateNode 节点合约

负责验证节点的信息维护和推荐关系维护

ValidateNode address is: 0xaf28eE5059523bC746c9eE2A463B6a3171689Fd8



### 方法

#### getValidatorNodeInfo根据节点地址获取节点信息 

```solidity
 function getValidatorNodeInfo(address nodeAddress) 
```

返回值：

```
			NodeInfo {
            string name;  // 节点名称
            address nodeAddress;// 节点地址
            uint8 nodeType; // 托管验证者 1、自建节点 2
            uint256 purchaseDuration; // 购买周期
            address agentAddress;	// 代理地址
            uint256 expiryDate;	//到期时间
            uint256 createTime;	// 创建时间
            address[] agentAddresses;// 节点的代理地址数组
            address[] clientAddress;	// 此节点绑定的委托人地址数组
        }
```

#### getAgentInfo根据带人地址获取代理人信息 

```solidity
function getAgentInfo(address agentAddress)
```

返回值：

```
AgentInfo {
            string name; //代理人名称
            address agentAddress;// 代理人地址
            address[] validitorNodeAddresses; // 代理人所代理的验证节点地址数组
            address[] clientAddresses;		// 通过此代理人的委托者
            uint256 purchaseDuration;		// 购买周期
            uint256 expiryDate;	// 释放时间
            uint256 payAmount;	//支付金额
            uint256 createTime;	// 创建时间
        }

```

#### getClient根据委托者地址获取委托者信息 

```
function getClient(address clientAddress)
```

返回值：

```
ClientInfo {
            address clientAddress; 	// 委托者地址
            address[] validatorNodeAddresses;	//委托者所在的验证节点数组
            address[] agentAddresses; 	// 委托者所在的代理
        }
```



## ValidateNodeManage 节点管理合约

负责验证节点、代理的购买、注册

ValidateNodeManage address is: 0x04f41eB54c2Cc2aFC8437083Dc3255D62d759788

Signer: 0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9

domain

```
DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("NodeManage")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
```



### buyNode 购买验证节点 

#### 方法

```
 function buyNode(bytes memory data) public
```

#### permit

```
bytes32 private constant PERMIT_BUYVALIDITENODE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 purchaseDuration,address tokenAddress,uint256 payAmount,address feeTo,uint256 expiryDate,address agentAddress,uint256 nonce)"
            )
        );
```

```
						(
                uint256 orderId,
                string memory name,
                uint256 purchaseDuration,
                address tokenAddress,
                uint256 payAmount,
                address feeTo,
                uint256 expiryDate,
                address agentAddress,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    string,
                    uint256,
                    address,
                    uint256,
                    address,
                    uint256,
                    address,
                    uint256,
                    bytes
                )
            );
```



#### event

```
event BuyNode(uint256 orderId,string name,uint256 purchaseDuration,address tokenAddress,uint256 payAmount,address feeTo,uint256 expiryDate,address agentAddress,uint256 nonce,uint256 createTime);
```

- orderId 购买节点的订单id
- name 节点名称
- purchaseDuration 购买周期
- tokenAddress 购买所使用的token
- payAmount 购买指数的数量
- feeTo 手续费的接收者
- expiryDate 到期时间
- nonce
- createTime 创建时间

### registNode 注册节点

#### 方法

```
 function registNode( 
            uint8 nodeType,
            string memory name,
            uint256 nonce,
            address nodeAddress) public onlyRole(OPERATE_ROLE)
```



- nodeType 节点类型  1 托管  2 自建节点
- name 用户自定义名称
- nonce
- nodeAddress 节点地址

#### event

```
event RegistNode(uint8 nodeType,string name,address nodeAddress,uint256 nonce,uint256 createTime);
```



### registAgent代理人注册

#### 方法

```
function registAgent(bytes memory data)
```

#### permit

```
 bytes32 private constant PERMIT_REGISTAGENT_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 purchaseDuration,address agentAddress,address feeTo,uint256 expiryDate,uint256 payAmount,uint256 nonce)"
            )
        );
```



```
 						(
                uint256 orderId,
                string memory name,
                uint256 purchaseDuration,
                address agentAddress,
                address feeTo,
                uint256 expiryDate,
                uint256 payAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    string,
                    uint256,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    bytes
                )
            );

```

- name 未进行签名

#### event

```
event RegistAgent(uint256 orderId,string name,uint256 purchaseDuration,address agentAddress,address feeTo,uint256 expiryDate,uint256 payAmount,uint256 nonce,uint256 createTime);
```



### renewAgent代理人续费

#### 方法

```
function renewAgent(bytes memory data)
```

#### permit

```
bytes32 private constant PERMIT_RENEWAGENT_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 purchaseDuration,uint256 expiryDate,address agentAddress,uint256 payAmount,uint256 nonce)"
            )
        );
```

```
 						(
                uint256 orderId,
                uint256 purchaseDuration,
                uint256 expiryDate,
                address agentAddress,
                uint256 payAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    uint256,
                    address,
                    uint256,
                    uint256,
                    bytes
                )
            );
```

- orderId 是续费的orderId

#### event

```
 event RenewAgent(uint256 orderId,uint256 purchaseDuration,uint256 expiryDate,address agentAddress,uint256 payAmount,uint256 nonce,uint256 createTime);
```



## Staking 质押合约

Staking address is: 0xAb71f42D296DbbdCc4D06AA2250173469e6AFFeD

domain:

```
DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("Staking")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
```



### validiatorStake 验证者质押

#### 方法

```
function validiatorStake(bytes memory data) public
```



#### permit

```
 bytes32 private constant PERMIT_VALIDATORSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce)"
            )
        );
```

```
						(
                uint256 orderId,
                address validatorAddress,
                address agentAddress,
                uint256 stakeDuration,
                uint256 stakeAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    bytes
                )
            );
```

#### event

```
event ValidiatorStake(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce,uint256 stakeTime);
```



### validiatorUnStake验证者撤出质押

#### 方法

```
function validiatorUnStake(bytes memory data) public  nonReentrant payable
```

#### permit

```
bytes32 private constant PERMIT_UNSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 nonce)"
            )
        );
```

```
						(
                uint256 orderId,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    bytes
                )
            );
```



#### event

```
  event ValidiatorUnStake(uint256 orderId,address valodator,uint256 stakeAmount,uint256 unstakeTime);
```



### agentStake 代理人质押

#### 方法

```
function agentStake(bytes memory data) public  
```

#### permit

```
bytes32 private constant PERMIT_AGENTSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce)"
            )
        );
```

```
						(
                uint256 orderId,
                address validatorAddress,
                address agentAddress,
                uint256 stakeDuration,
                uint256 stakeAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    bytes
                )
            );
```

#### event

```
event AgentStake(uint256 orderId,address validatorAddress,address agentAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce,uint256 stakeTime);
```

### agentUnStake代理人撤出质押

#### 方法

```
function agentUnStake(bytes memory data) public  nonReentrant payable 
```

#### permit

```
bytes32 private constant PERMIT_UNSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 nonce)"
            )
        );
```

```
   					(
                uint256 orderId,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    bytes
                )
            );
```

#### event

```
event AgentUnStake(uint256 orderId,address valodator,uint256 stakeAmount,uint256 unstakeTime);
```







### clientStake 委托者质押

#### 方法

```
function clientStake(bytes memory data) public
```



#### permit

```
bytes32 private constant PERMIT_CLIENTSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,address validatorAddress,address agentAddress,address clientAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce)"
            )
        );
```



```
 						(
                uint256 orderId,
                address validatorAddress,
                address agentAddress,
                address clientAddress,
                uint256 stakeDuration,
                uint256 stakeAmount,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    address,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    bytes
                )
            );
```



#### event

```
event ClientStake(uint256 orderId,address validatorAddress,address agentAddress,address clientAddress,uint256 stakeDuration,uint256 stakeAmount,uint256 nonce,uint256 stakeTime);
```



### clientUnStake委托人撤出质押

#### 方法

```
function clientUnStake(bytes memory data) public  nonReentrant payable 
```

#### permit

```
bytes32 private constant PERMIT_UNSTAKE_TYPEHASH = keccak256(
            abi.encodePacked(
                "Permit(uint256 orderId,uint256 nonce)"
            )
        );
```

```
 						(
                uint256 orderId,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    bytes
                )
            );
```



#### event

```
event ClientUnStake(uint256 orderId,address valodator,uint256 stakeAmount,uint256 unstakeTime);
```



## PIJSStakingRewardDistribute 奖励合约

PIJSStakingRewardDistribute address is: 0x0202361152f9F8c9c40CeB7b6B80E1384f648bDE

domain

```
 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("StakingRewardDistribute")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
```



#### generateRewards 往合约转奖励

#### 方法

```
function generateRewards(uint256 yyyymmdd) public onlyRole(OPERATE_ROLE) nonReentrant payable
```

- yyyymmdd 年月日 

  此方法每日调用多次

#### 事件

```
event GenerateRewards(address operator,uint256 yyyymmdd,uint256 amount,uint256 amountSum,uint256 createTime);
```



#### withdrawReward奖励领取

#### 方法

```
 function withdrawReward(bytes memory data) public nonReentrant  onlyRole(OPERATE_ROLE) 
```

#### permit

```
bytes32 private constant PERMIT_WITHDRAWREWARD_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(uint256 orderId,uint256 amount,address beneficiaryAddress,uint256 nonce)"
        )
    );
```

```
 				(
            uint256 orderId,
            uint256 amount,
            address beneficiaryAddress,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                uint256,
                uint256,
                address,
                uint256,
                bytes
            )
        );
```



#### event

```
 event WithdrawReward(uint256 orderId,uint256 amount,address beneficiaryAddress,uint256 nonce,uint256 withdrawTime);
```





