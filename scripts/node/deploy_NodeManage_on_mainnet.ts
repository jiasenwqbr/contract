import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {GenesisNode,NodeManage} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    const singer = "0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9";
    // const singer = owner.address;
    // const feeReceiver = operator.address;
    // const feeReceiver1 = operator.address;
    const usdt_address = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD";
    const node_address = "0x8d424Fa56217B671f47FBEA3384a652d0F8758b1";

    const nodeManageFactory = await ethers.getContractFactory("NodeManage");
    const args = [singer,["0xF2CB4D9794bA154748ca8EfC291Bb17762f6beB4","0xD5779F9140b58b81B1fc1d335E674305aC0144e8","0x13a0592678D18ddCEEB2e89F0d82990F98902dC6"],[300,300,300],usdt_address];
    const nodeManage = (await upgrades.deployProxy(nodeManageFactory,args,{initializer: "initialize",kind:'uups'})) as NodeManage;
    // const nodeManage = await upgrades.upgradeProxy('0xDA5247462737e50dBe85F15d5596c494225F3307', nodeManageFactory, { kind: 'uups' });
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


 */