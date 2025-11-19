import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {MintPool} from  "../../../typechain-types";
async function main(){

    const [owner,user1] = await ethers.getSigners();
    const operator = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const to = '0x3C875e921F7F963560E42Bc682EA542decFe73Fa';
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
npx hardhat run ./scripts/bridge_standard/mainnet/deploy_MintPool_on_mainnet.ts --network pijs

MintPool address is: 0x327303DB1E5a36Bb34c656c40c50E5020F4B7B53
operator address is: 0xf504551185C4B3ee73e9D96eeA06e3FD4210E601
to address is: 0x3C875e921F7F963560E42Bc682EA542decFe73Fa
 */