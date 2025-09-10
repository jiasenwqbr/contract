# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts

```

初始化hardhat项目


```bash
## 创建项目文件夹
mkdir bonding-curve
cd bonding-curve
## 初始化 package.json
npm init -y

npx hardhat

npx hardhat --init


```


```bash
npm install dotenv --save-dev



```
创建 .env 文件

修改 hardhat.config.ts

```ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const BSCTEST_RPC = process.env.BSCTEST_RPC || "";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    hardhat: {},
    bsctest: {
      url: BSCTEST_RPC,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
};

export default config;

```
