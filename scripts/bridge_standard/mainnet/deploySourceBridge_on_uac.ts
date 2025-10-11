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
    // const sourceBridgeDeploy = await upgrades.upgradeProxy('0x881d05D8E12aABE3fF06105551b44f1976DB8c44', SourceBridgeContract, { kind: 'uups' });
    const sourceBridgeDeploy =  await upgrades.deployProxy(SourceBridgeContract,args,{kind:'uups'});

    await sourceBridgeDeploy.deployed();

    
    console.log("SourceBridge address is : ",sourceBridgeDeploy.address);

}

main().catch(error=> {
        console.error(error);
    process.exitCode = 1;
});

/***

npx hardhat run ./scripts/bridge_standard/mainnet/deploySourceBridge_on_uac.ts --network uac
SourceBridge address is :  0x881d05D8E12aABE3fF06105551b44f1976DB8c44
 */