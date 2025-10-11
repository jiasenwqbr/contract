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
    const SourceBridgeContract = await ethers.getContractFactory('BridgeTargetV1');
    // const sourceBridgeDeploy = await upgrades.upgradeProxy('0x18E11768B9178FB2bdF299020653154550095dE3', SourceBridgeContract, { kind: 'uups' });
    const sourceBridgeDeploy =  await upgrades.deployProxy(SourceBridgeContract,args,{kind:'uups'});

    await sourceBridgeDeploy.deployed();

    
    console.log("BridgeTargetV1 address is : ",sourceBridgeDeploy.address);

}

main().catch(error=> {
        console.error(error);
    process.exitCode = 1;
});

/***

npx hardhat run ./scripts/bridge_standard/mainnet/deployBridgeTargetV1_on_mainnet.ts --network pijs
BridgeTargetV1 address is :  0x18E11768B9178FB2bdF299020653154550095dE3
 */