import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {StakingUAG,MarketMakerStake} from  "../../../typechain-types";
async function main(){
    const [owner] = await ethers.getSigners();
    const marketMakerStakeFactory = await ethers.getContractFactory('MarketMakerStake');
    const signer = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const uagAddress = '0x0b5E6Ef97FF0E013eB502735769e98fD4c538FE9';
    const uacAddress = '0xe15B602eF891D45251FF749BE97db6a983CdE175';
    const usdtAddress = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const feeAddress = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const args = [signer,uagAddress,uacAddress,usdtAddress,feeAddress];
    // const marketMakerStake =  (await upgrades.deployProxy(marketMakerStakeFactory,args,{kind:'uups'})) as MarketMakerStake;
    const marketMakerStake = await upgrades.upgradeProxy('0xeE50Fae73fd72838F91e328390b524e4167f0F5E', marketMakerStakeFactory, { kind: 'uups' });
    await marketMakerStake.deployed();
    console.log("MarketMakerStake address is:",marketMakerStake.address);

}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
 npx hardhat run ./scripts/bridge/testnet/deployMarketMakerStake_on_testnet.ts --network pijstestnet
MarketMakerStake address is: 0xeE50Fae73fd72838F91e328390b524e4167f0F5E
 */