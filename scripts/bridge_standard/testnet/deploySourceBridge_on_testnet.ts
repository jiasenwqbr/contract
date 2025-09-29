import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SourceBridge} from  "../../../typechain-types";

async function main(){
    const [owner,singer] = await ethers.getSigners();
    const feeReceiver_address = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const signer_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const feePercentage = 50;
    const args = [feeReceiver_address,signer_address,operator_address,feePercentage];
    const SourceBridgeContract = await ethers.getContractFactory('SourceBridge');
    const sourceBridgeDeploy = await upgrades.upgradeProxy('0x8B769E9BE8271e07a0ccb9b53E57d659D0963fe4', SourceBridgeContract, { kind: 'uups' });
    // const sourceBridgeDeploy =  await upgrades.deployProxy(SourceBridgeContract,args,{kind:'uups'});

    await sourceBridgeDeploy.deployed();

    
    console.log("SourceBridge address is : ",sourceBridgeDeploy.address);

}

main().catch(error=> {
        console.error(error);
    process.exitCode = 1;
});

/***

npx hardhat run ./scripts/bridge_standard/testnet/deploySourceBridge_on_testnet.ts --network uac
SourceBridge address is :  0x8B769E9BE8271e07a0ccb9b53E57d659D0963fe4
 */