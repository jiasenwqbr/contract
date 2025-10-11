import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {StakingUAG} from  "../../../typechain-types";
async function main(){
    const [owner] = await ethers.getSigners();
    const stakingUAGFactory = await ethers.getContractFactory('StakingUAG');
    const signer = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const uagAddress = '0x0b5E6Ef97FF0E013eB502735769e98fD4c538FE9';
    const uacAddress = '0xe15B602eF891D45251FF749BE97db6a983CdE175';
    const feeAddress = '0x2D703c5fcd6F99be0d87F7Dfd19080e2Ea4c4a92';
    const stakeAmountMin = ethers.utils.parseEther("10");
    const stakeAmountMax= ethers.utils.parseEther("1000");
    const withdrawalFeePersentage = 50;

    const gensisNodeDistribute = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const ecoDevAddress = '0xE383D646ef73229421Ebf607d4CCe2B199a12078'; // 生态建设
    const insuranceWarehouse = '0x4f5f15f22206347471b0C0555d78EBec9a96e8D6';  // 保险仓

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

    const stakingUAG =  (await upgrades.deployProxy(stakingUAGFactory,args,{kind:'uups'})) as StakingUAG;
    // const stakingUAG = await upgrades.upgradeProxy('0xe59C1e736278f0F5b893217E07E44eedaa6C81E9', stakingUAGFactory, { kind: 'uups' });
    await stakingUAG.deployed();
    console.log("StakingUAG address is:",stakingUAG.address);
    const ratio:[number, number, number, number] = [15,10,25,50];
    const tx = await stakingUAG.setUacdistributeRadio(ratio);
    await tx.wait();
    console.log("ratio:",await stakingUAG.getUacdistributeRadio());

    const tx3 = await stakingUAG.setUacDistributeAddress(
        ['0x0000000000000000000000000000000000000000',gensisNodeDistribute,ecoDevAddress,insuranceWarehouse]
    );
    await tx3.wait();
    console.log("uacDistributeAddress:",await stakingUAG.getUacDistributeAddress());


}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/bridge_standard/mainnet/deployStakingUAG_on_mainnet.ts --network pijstestnet
StakingUAG address is: 0xe59C1e736278f0F5b893217E07E44eedaa6C81E9
 */