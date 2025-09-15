import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {GenesisNode,NodeManage} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    const singer = "0xf504551185c4b3ee73e9d96eea06e3fd4210e601";
    // const singer = owner.address;
    // const feeReceiver = operator.address;
    // const feeReceiver1 = operator.address;
    const usdt_address = "0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B";
    const node_address = "0x8d424Fa56217B671f47FBEA3384a652d0F8758b1";

    const nodeManageFactory = await ethers.getContractFactory("NodeManage");
    const args = [singer,["0x3fCabB322Da8920b0003009C1123c1e900e555f3","0x892384A787044Fb6Dd5654B2Ec3A5500e3139aC5","0x80D1B364Eb8a2b2B8aAB2d989bDB188B61A82237"],[500,300,100],usdt_address];
    const nodeManage = (await upgrades.deployProxy(nodeManageFactory,args,{initializer: "initialize",kind:'uups'})) as NodeManage;
    // const nodeManage = await upgrades.upgradeProxy('0x8C74f5eB3efd80619A58fDE11f19c2744c2Cb90a', nodeManageFactory, { kind: 'uups' });
    await nodeManage.deployed();

    console.log("NodeManage address is:",nodeManage.address);
    

    const genesisNode = (await ethers.getContractAt("GenesisNode",node_address)) as GenesisNode;
    const tx1 = await genesisNode.grantRole(await genesisNode.OPERATOR_ROLE(),nodeManage.address);
    await tx1.wait();
    const hasRole = await genesisNode.hasRole(await genesisNode.OPERATOR_ROLE(),nodeManage.address);
    console.log("hasRole:",hasRole);
    const tx = await nodeManage.connect(owner).addProduct(1,node_address,true);
    await tx.wait();
}

main().catch(error => {
    console.log(error);
    process.exitCode = 1;
}) ;

/**
npx hardhat run ./scripts/node/deploy_NodeManage_on_mainnet.ts --network pijs

生产环境：
GenesisNode address is: 0x8d424Fa56217B671f47FBEA3384a652d0F8758b1
NodeManage address is: 0xE6a51D9FdD1B60941A060e54209C4714eA5db466
 */