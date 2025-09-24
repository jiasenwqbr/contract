import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {BridgeTarget} from  "../../../typechain-types";

async function main(){
    const [owner,singer] = await ethers.getSigners();
    const feeReceiver_address = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const signer_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const feePercentage = 50;
    const args = [feeReceiver_address,operator_address,feePercentage,signer_address];
    const BridgeTargetContract = await ethers.getContractFactory('BridgeTarget');
    // const bridgeTargetDeploy =  await upgrades.deployProxy(BridgeTargetContract,args,{kind:'uups'});
    const bridgeTargetDeploy = await upgrades.upgradeProxy('0x7b29d757ba9Dd7eCaB4C24aE88F4E62eD2E86766', BridgeTargetContract, { kind: 'uups' });
    await bridgeTargetDeploy.deployed();
    console.log("BridgeTarget address is : ",bridgeTargetDeploy.address);
}

main().catch(error=> {
    console.error(error);
    process.exitCode = 1;
});

/***

npx hardhat run ./scripts/bridge_standard/testnet/deployTargetBridge_on_testnet.ts --network pijstestnet
BridgeTarget address is :  0x7b29d757ba9Dd7eCaB4C24aE88F4E62eD2E86766
 */