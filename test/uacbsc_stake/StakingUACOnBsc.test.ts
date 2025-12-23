import { expect } from "chai";
import { ethers,upgrades,network } from "hardhat";
import { UACBSC , StakingUACOnBsc } from  "../../typechain-types";


describe("StakingUACOnBsc test",() => {
    
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    let uac:UACBSC;
    let stakingUACOnBsc:StakingUACOnBsc;
    let uac_address = "0x4A20C6BE6d1952c1D6529b3CdB361D426c897231";
    let stakingUACOnBsc_address = "0x145d54E0BE098acfBb9EBdbC83C72e5e897f7d64";

    beforeEach(async () => {
        [owner,user1,user2,user3] = await ethers.getSigners();
        uac = await ethers.getContractAt("UACBSC",uac_address);
        stakingUACOnBsc = await ethers.getContractAt("StakingUACOnBsc",stakingUACOnBsc_address);
        
        console.log("owner balance is:",await uac.balanceOf(owner.address));
        console.log("user1 balance is:",await uac.balanceOf(user1.address));
        console.log("user2 balance is:",await uac.balanceOf(user2.address));
        console.log("StakingUACOnBsc balance is:",await uac.balanceOf(user2.address));
    });
    it("test owner stake total is right",async () => {
        const totalStakedBefore = await stakingUACOnBsc.totalStaked();
        const userStakedBefore = (await stakingUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedBefore:",ethers.utils.formatEther(totalStakedBefore));
        console.log("userStakedBefore:",ethers.utils.formatEther(userStakedBefore));

        let amount = ethers.utils.parseEther("200");
        const tx1 = await uac.connect(owner).approve(stakingUACOnBsc.address,ethers.utils.parseEther("200"));
        await tx1.wait();
        const tx = await stakingUACOnBsc.connect(owner).stake(amount,uac_address,{
                 gasLimit: 1_000_000,
        });
        await tx.wait();

        const totalStakedAfter = await stakingUACOnBsc.totalStaked();
        const userStakedAfter = (await stakingUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedAfter:",ethers.utils.formatEther(totalStakedAfter));
        console.log("userStakedAfter:",ethers.utils.formatEther(userStakedAfter));

        console.log("getPerDays:",await stakingUACOnBsc.getPerDays(0,10));
        console.log("owner --> getUserPerDays:",await stakingUACOnBsc.getUserPerDays(owner.address,0,10));

        console.log("User info:",await stakingUACOnBsc.users(owner.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.add(amount));
        expect(userStakedAfter).to.equal(userStakedBefore.add(amount));

    });

    it("test user1 stake total is right",async () => {
        const totalStakedBefore = await stakingUACOnBsc.totalStaked();
        const userStakedBefore = (await stakingUACOnBsc.users(user1.address)).amount;
        console.log("totalStakedBefore:",ethers.utils.formatEther(totalStakedBefore));
        console.log("userStakedBefore:",ethers.utils.formatEther(userStakedBefore));

        let amount = ethers.utils.parseEther("100");
        const tx1 = await uac.connect(user1).approve(stakingUACOnBsc.address,ethers.utils.parseEther("100"));
        await tx1.wait();
        const tx = await stakingUACOnBsc.connect(user1).stake(amount,uac_address,{
                 gasLimit: 1_000_000,
        });
        await tx.wait();

        const totalStakedAfter = await stakingUACOnBsc.totalStaked();
        const userStakedAfter = (await stakingUACOnBsc.users(user1.address)).amount;
        console.log("totalStakedAfter:",ethers.utils.formatEther(totalStakedAfter));
        console.log("userStakedAfter:",ethers.utils.formatEther(userStakedAfter));

        console.log("getPerDays:",await stakingUACOnBsc.getPerDays(0,10));
        console.log("owner --> getUserPerDays:",await stakingUACOnBsc.getUserPerDays(user1.address,0,10));

        console.log("User info:",await stakingUACOnBsc.users(user1.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.add(amount));
        expect(userStakedAfter).to.equal(userStakedBefore.add(amount));

    });


    it("test unstake",async () => {
        const totalStakedBefore = await stakingUACOnBsc.totalStaked();
        const userStakedBefore = (await stakingUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedBefore:",ethers.utils.formatEther(totalStakedBefore));
        console.log("userStakedBefore:",ethers.utils.formatEther(userStakedBefore));

        let amount = ethers.utils.parseEther("100");
        const tx1 = await uac.connect(owner).approve(stakingUACOnBsc.address,ethers.utils.parseEther("100"));
        await tx1.wait();
        const tx = await stakingUACOnBsc.connect(owner).unStake(amount,uac_address,{
                 gasLimit: 1_000_000,
        });
        await tx.wait();

        const totalStakedAfter = await stakingUACOnBsc.totalStaked();
        const userStakedAfter = (await stakingUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedAfter:",ethers.utils.formatEther(totalStakedAfter));
        console.log("userStakedAfter:",ethers.utils.formatEther(userStakedAfter));

        console.log("getPerDays:",await stakingUACOnBsc.getPerDays(0,10));
        console.log("owner --> getUserPerDays:",await stakingUACOnBsc.getUserPerDays(owner.address,0,10));

        console.log("User info:",await stakingUACOnBsc.users(owner.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.sub(amount));
        expect(userStakedAfter).to.equal(userStakedBefore.sub(amount));
    });
    it("test calculate reward",async () => {

        // const tx1 = await uac.connect(owner).transfer(stakingUACOnBsc.address,ethers.utils.parseEther("10000000"));
        // await tx1.wait();
        // console.log("StakingUACOnBsc balance is:",await uac.balanceOf(stakingUACOnBsc.address));

        const tx = await stakingUACOnBsc.connect(owner).calculateReward({
            gasLimit: 1_000_000,
        });
        await tx.wait();

        const tx1 = await stakingUACOnBsc.connect(user1).calculateReward({
            gasLimit: 1_000_000,
        });
        await tx1.wait();

        console.log("User info:",await stakingUACOnBsc.users(owner.address));
        console.log("Owner info:",await stakingUACOnBsc.users(owner.address));
        console.log("User1 info:",await stakingUACOnBsc.users(user1.address));
        console.log("Owner rewardBalance:", ethers.utils.formatEther((await stakingUACOnBsc.users(owner.address)).rewardBalance) );
        console.log("User1 rewardBalance:", ethers.utils.formatEther((await stakingUACOnBsc.users(user1.address)).rewardBalance) );
        console.log("getPerDays:",await stakingUACOnBsc.getPerDays(0,10));


        // console.log("total 490522:",ethers.utils.formatEther((await stakingUACOnBsc.getTotalStakePerDay(490522))) );
        // console.log("total 490523:",ethers.utils.formatEther((await stakingUACOnBsc.getTotalStakePerDay(490523))) );
        // console.log("total 490525:",ethers.utils.formatEther((await stakingUACOnBsc.getTotalStakePerDay(490525))) );
        // console.log("total 490526:",ethers.utils.formatEther((await stakingUACOnBsc.getTotalStakePerDay(490526))) );
        // console.log("total 490537:",ethers.utils.formatEther((await stakingUACOnBsc.getTotalStakePerDay(490537))) );
        // console.log("total 490538:",ethers.utils.formatEther((await stakingUACOnBsc.getTotalStakePerDay(490538))) );

        // console.log("user total 490522:",ethers.utils.formatEther((await stakingUACOnBsc.getUserTotalStakePerDay(490522,owner.address))) );
        // console.log("user total 490523:",ethers.utils.formatEther((await stakingUACOnBsc.getUserTotalStakePerDay(490523,owner.address))) );
        // console.log("user total 490525:",ethers.utils.formatEther((await stakingUACOnBsc.getUserTotalStakePerDay(490525,owner.address))) );
        // console.log("user total 490526:",ethers.utils.formatEther((await stakingUACOnBsc.getUserTotalStakePerDay(490526,owner.address))) );
        // console.log("user total 490537:",ethers.utils.formatEther((await stakingUACOnBsc.getUserTotalStakePerDay(490537,owner.address))) );
        // console.log("user total 490538:",ethers.utils.formatEther((await stakingUACOnBsc.getUserTotalStakePerDay(490538,owner.address))) );

    });

    it("test withdraw reward",async () => {
        const beforeBalance = await uac.balanceOf(owner.address);
        console.log("before balance:",beforeBalance);
        const tx = await stakingUACOnBsc.connect(owner).withDrawReward(uac_address,ethers.utils.parseEther("40"));
        await tx.wait();

        const afterBalance = await uac.balanceOf(owner.address);
        console.log("after balance:",afterBalance);

        expect(afterBalance).to.equal(beforeBalance.add(ethers.utils.parseEther("40")));


    });

    it("search",async () => {
        console.log("User info:",await stakingUACOnBsc.users(owner.address));
        console.log("Owner info:",await stakingUACOnBsc.users(owner.address));
        console.log("User1 info:",await stakingUACOnBsc.users(user1.address));
        console.log("Owner rewardBalance:", ethers.utils.formatEther((await stakingUACOnBsc.users(owner.address)).rewardBalance) );
        console.log("User1 rewardBalance:", ethers.utils.formatEther((await stakingUACOnBsc.users(user1.address)).rewardBalance) );
        console.log("getPerDays:",await stakingUACOnBsc.getPerDays(0,10));
    });





});



/**
npx hardhat test ./test/uacbsc_stake/StakingUACOnBsc.test.ts --network ganache --grep "test calculate reward"
npx hardhat test ./test/uacbsc_stake/StakingUACOnBsc.test.ts --network ganache --grep "search"
 */