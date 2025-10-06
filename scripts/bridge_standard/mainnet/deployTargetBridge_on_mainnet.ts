import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {BridgeTarget} from  "../../../typechain-types";

async function main(){
    const [owner,singer] = await ethers.getSigners();
    const feeReceiver_address = '0x2D703c5fcd6F99be0d87F7Dfd19080e2Ea4c4a92';
    const operator_address = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const signer_address = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const feePercentage = 50;
    const args = [feeReceiver_address,operator_address,feePercentage,signer_address];
    const BridgeTargetContract = await ethers.getContractFactory('BridgeTarget');
    const bridgeTargetDeploy =  await upgrades.deployProxy(BridgeTargetContract,args,{kind:'uups'});
    // const bridgeTargetDeploy = await upgrades.upgradeProxy('0x7b29d757ba9Dd7eCaB4C24aE88F4E62eD2E86766', BridgeTargetContract, { kind: 'uups' });

     await bridgeTargetDeploy.deployed();
    // const bridgeTargetDeploy = await ethers.getContractAt("BridgeTarget","0xa984d62B1E8da0A2372348C01d4140B7BfCC5c29");
    console.log("BridgeTarget address is : ",bridgeTargetDeploy.address);
    const tx2 = await bridgeTargetDeploy.grantRole(await bridgeTargetDeploy.OPERATE_ROLE(),operator_address);
    await tx2.wait();


}

main().catch(error=> {
    console.error(error);
    process.exitCode = 1;
});

/***

npx hardhat run ./scripts/bridge_standard/mainnet/deployTargetBridge_on_mainnet.ts --network pijs
BridgeTarget address is :  0xa984d62B1E8da0A2372348C01d4140B7BfCC5c29
 */