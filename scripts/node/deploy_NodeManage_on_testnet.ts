import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {GenesisNode,NodeManage} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    const singer = owner.address;
    const feeReceiver = operator.address;
    const feeReceiver1 = operator.address;
    const usdt_address = "0xf7164a0fEBF00D1af7A3D710585093af2E13d79B";
   

    const nodeManageFactory = await ethers.getContractFactory("NodeManage");
    const args = [singer,[operator.address,operator.address,operator.address],[300,300,300],usdt_address];
    const nodeManage = (await upgrades.deployProxy(nodeManageFactory,args,{initializer: "initialize",kind:'uups'})) as NodeManage;
    await nodeManage.deployed();

    console.log("NodeManage address is:",nodeManage.address);
    const node_address = "0x95158dD21b82d8D2f62aaB88f45E5e365e1B9f27";

    const genesisNode = (await ethers.getContractAt("GenesisNode",node_address)) as GenesisNode;
    await genesisNode.grantRole(await genesisNode.OPERATOR_ROLE(),nodeManage.address);
    const hasRole = await genesisNode.hasRole(await genesisNode.OPERATOR_ROLE(),nodeManage.address);
    console.log("hasRole:",hasRole);
}

main().catch(error => {
    console.log(error);
    process.exitCode = 1;
}) ;

/**
npx hardhat run ./scripts/node/deploy_NodeManage_on_testnet.ts --network pijstestnet
NodeManage address is: 0x984614a7780e09465732E5B347682e291C999cBd

 */