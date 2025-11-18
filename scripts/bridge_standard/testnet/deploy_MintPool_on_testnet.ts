import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {MintPool} from  "../../../typechain-types";
async function main(){

    const [owner,user1] = await ethers.getSigners();
    const operator = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const to = '0x4110E09f615dcE2BC6F75f1fC6713310CC554BcC';
    const args=[operator,to];

    const factory = await ethers.getContractFactory('MintPool');
    const mintPool =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as MintPool;
    // const mintPool = await upgrades.upgradeProxy('0x4110E09f615dcE2BC6F75f1fC6713310CC554BcC', rewardDistributeUAGFactory, { kind: 'uups' });
    await mintPool.deployed();
    console.log("MintPool address is:",await mintPool.address);
    console.log("operator address is:",await mintPool.operator());
    console.log("to address is:",await mintPool.to());

    


}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/bridge_standard/testnet/deploy_MintPool_on_testnet.ts --network pijstestnet

MintPool address is: 0x2726FFA8C403f7F4dcc4c959E5e3787EEdA23513
operator address is: 0xd4F0f0c79A35f217E5DE4BFf0752bA63cbC013e9
to address is: 0x4110E09f615dcE2BC6F75f1fC6713310CC554BcC
 */