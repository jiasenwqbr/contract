import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SourceBridge} from  "../../../typechain-types";

async function main(){
    const [owner,singer] = await ethers.getSigners();
    const feeReceiver_address = '0x286bb1a1C69DaeF6f4b551c4DAaA44Eb7651a37b';

    const signer_address = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const operator_address = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const feePercentage = 60;
    const args = [feeReceiver_address,signer_address,operator_address,feePercentage];
    const SourceBridgeContract = await ethers.getContractFactory('SourceBridge');
    // const sourceBridgeDeploy = await upgrades.upgradeProxy('0x8B769E9BE8271e07a0ccb9b53E57d659D0963fe4', SourceBridgeContract, { kind: 'uups' });
    const sourceBridgeDeploy =  await upgrades.deployProxy(SourceBridgeContract,args,{kind:'uups'});

    await sourceBridgeDeploy.deployed();

    
    console.log("SourceBridge address is : ",sourceBridgeDeploy.address);

}

main().catch(error=> {
        console.error(error);
    process.exitCode = 1;
});

/***

npx hardhat run ./scripts/bridge_standard/mainnet/deploySourceBridge_on_mainnet.ts --network pijs
SourceBridge address is :  
 */