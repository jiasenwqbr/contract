import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {StakingUAG} from  "../../typechain-types";
async function main(){
    const [owner] = await ethers.getSigners();
    const stakingUAGFactory = await ethers.getContractFactory('StakingUAG');
    const signer = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const uagAddress = '0x0b5E6Ef97FF0E013eB502735769e98fD4c538FE9';
    const uacAddress = '0xe15B602eF891D45251FF749BE97db6a983CdE175';
    const feeAddress = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const stakeAmountMin = ethers.utils.parseEther("10");
    const stakeAmountMax= ethers.utils.parseEther("1000");
    const withdrawalFeePersentage = 50;

    const gensisNodeDistribute = feeAddress;
    const ecoDevAddress = feeAddress;
    const insuranceWarehouse = feeAddress;

    const args = [
        signer,
        uagAddress,
        uacAddress,
        feeAddress,
        stakeAmountMin,
        stakeAmountMax,
        withdrawalFeePersentage,
        gensisNodeDistribute,
        ecoDevAddress,
        insuranceWarehouse
    ];

    // const stakingUAG =  (await upgrades.deployProxy(stakingUAGFactory,args,{kind:'uups'})) as StakingUAG;
    const stakingUAG = await upgrades.upgradeProxy('0xe59C1e736278f0F5b893217E07E44eedaa6C81E9', stakingUAGFactory, { kind: 'uups' });
    await stakingUAG.deployed();
    console.log("StakingUAG address is:",stakingUAG.address);
    const ratio = [15,10,25,50];
    const tx = await stakingUAG.setUacdistributeRadio(ratio);
    await tx.wait();
    console.log("ratio:",await stakingUAG.getUacdistributeRadio());

    const tx3 = await stakingUAG.setUacDistributeAddress(
        [feeAddress,'0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9',feeAddress,feeAddress]
    );
    await tx3.wait();
    console.log("uacDistributeAddress:",await stakingUAG.getUacDistributeAddress());


    const tx6 = await stakingUAG.setStakeAmountLimit(ethers.utils.parseEther("10"),ethers.utils.parseEther("100000"));
    await tx6.wait();
    const [min,max]  = await stakingUAG.getStakeAmountLimit();
    console.log("min:",min,"max:",max);


    



}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/node/deployStakingUAG_on_testnet.ts --network pijstestnet
StakingUAG address is: 0xe59C1e736278f0F5b893217E07E44eedaa6C81E9
 */