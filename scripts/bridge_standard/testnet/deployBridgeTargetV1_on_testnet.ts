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
    const bridgeContract = await ethers.getContractFactory('BridgeTargetV1');
    // const bridgeContract = await upgrades.upgradeProxy('0x8B769E9BE8271e07a0ccb9b53E57d659D0963fe4', SourceBridgeContract, { kind: 'uups' });
    const targetBridgeDeploy =  await upgrades.deployProxy(bridgeContract,args,{kind:'uups'});

    await targetBridgeDeploy.deployed();

    
    console.log("BridgeTargetV1 address is : ",targetBridgeDeploy.address);

}

main().catch(error=> {
        console.error(error);
    process.exitCode = 1;
});

/***

npx hardhat run ./scripts/bridge_standard/testnet/deployBridgeTargetV1_on_testnet.ts --network pijstestnet
BridgeTargetV1 address is :  0x18adcd7e9E3f98D00e8D189612e92d971ACeb20E
 */