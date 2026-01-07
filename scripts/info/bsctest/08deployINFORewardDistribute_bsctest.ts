import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,INFOErc20,DepositContract,INFORewardDistribute} from  "../../../typechain-types";

async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    
    const singer = "0xcdDa4F2ADD39Db9F64Ee43e7A825655e5c865FFd";
    // 0x843f834c0bd6cfd7a5253c509e41924b4eb5f0daeeca7bc4bbc28eb1971ef565
    const factory1 = await ethers.getContractFactory('INFORewardDistribute');
    // const iNFORewardDistribute =  (await upgrades.deployProxy(factory1,[singer],{kind:'uups'})) as INFORewardDistribute;
    const iNFORewardDistribute = await upgrades.upgradeProxy('0xFd5577f62435Cf6c721461B7fE6cF73eBEc754cD', factory1, { kind: 'uups' });
    await iNFORewardDistribute.deployed();
    console.log("INFORewardDistribute address is:",iNFORewardDistribute.address);

    //TODO setFeeAllocation
    const feeAllocationRatio = 100;
    const weighted_dividend_distribution_community_weekly_address = user1.address;
    const weighted_dividend_distribution_community_realtime_address = user1.address;
    const tx = await iNFORewardDistribute.setFeeAllocation(
        feeAllocationRatio,
        [500,500],
        [weighted_dividend_distribution_community_weekly_address,weighted_dividend_distribution_community_realtime_address]
    );

    await tx.wait();

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/bsctest/08deployINFORewardDistribute_bsctest.ts --network bscTest

INFORewardDistribute address is: 0xFd5577f62435Cf6c721461B7fE6cF73eBEc754cD



*/