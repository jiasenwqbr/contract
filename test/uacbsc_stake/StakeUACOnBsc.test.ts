import { expect } from "chai";
import { ethers,upgrades,network } from "hardhat";
import { UACBSC , StakeUACOnBsc,UacNFTT } from  "../../typechain-types";


describe("StakingUACOnBsc test",() => {
    
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    let uac:UACBSC;
    let nft:UacNFTT;
    let stakeUACOnBsc:StakeUACOnBsc;
    let uac_address = "0x4A20C6BE6d1952c1D6529b3CdB361D426c897231";
    let nft_address = "0x39c49C512178934a1DCd33176f4c85e842844EEb";
    let stakeUACOnBsc_address = "0x9ce2f3659190AB53b9b575072a6bCAD2008A686e";

    beforeEach(async () => {
        [owner,user1,user2,user3] = await ethers.getSigners();
        uac = await ethers.getContractAt("UACBSC",uac_address);

        stakeUACOnBsc = await ethers.getContractAt("StakeUACOnBsc",stakeUACOnBsc_address);
        nft = await ethers.getContractAt("UacNFTT",nft_address);
        
        console.log("owner balance is:",await uac.balanceOf(owner.address));
        console.log("user1 balance is:",await uac.balanceOf(user1.address));
        console.log("user2 balance is:",await uac.balanceOf(user2.address));
        console.log("StakingUACOnBsc balance is:",await uac.balanceOf(user2.address));

        console.log("owner nft balance is:",await nft.balanceOf(owner.address));
        console.log("user1 nft balance is:",await nft.balanceOf(user1.address));
        console.log("user2 nft balance is:",await nft.balanceOf(user2.address));
        console.log("StakingUACOnBsc nft balance is:",await nft.balanceOf(user2.address));
        // view user nfts
       
        console.log("owner staked nft:", await stakeUACOnBsc.stakedTokens(owner.address));
        console.log("user1 staked nft:", await stakeUACOnBsc.stakedTokens(user1.address));
        console.log("user2 staked nft:", await stakeUACOnBsc.stakedTokens(user2.address));
        console.log("user3 staked nft:", await stakeUACOnBsc.stakedTokens(user3.address));

        const countOwner = await nft.balanceOf(owner.address);
        console.log("NFT count:", countOwner.toString());
        // for (let i = 0; i < countOwner.toNumber(); i++) {
        //     const tokenId = await nft.tokenOfOwnerByIndex(owner.address, i);
        //     console.log("Token ID:", tokenId.toString());
        // }

        const countuser1 = await nft.balanceOf(user1.address);
        console.log("NFT countuser1:", countuser1.toString());
        // for (let i = 0; i < countuser1.toNumber(); i++) {
        //     const tokenId = await nft.tokenOfOwnerByIndex(user1.address, i);
        //     console.log("Token ID:", tokenId.toString());
        // }

        const countuser2 = await nft.balanceOf(user2.address);
        console.log("NFT countuser2:", countuser2.toString());
        for (let i = 0; i < countuser2.toNumber(); i++) {
            const tokenId = await nft.tokenOfOwnerByIndex(user2.address, i);
            console.log("Token ID:", tokenId.toString());
        }
        const countuser3 = await nft.balanceOf(user3.address);
        console.log("NFT countuser3:", countuser3.toString());
        for (let i = 0; i < countuser3.toNumber(); i++) {
            const tokenId = await nft.tokenOfOwnerByIndex(user3.address, i);
            console.log("Token ID:", tokenId.toString());
        }

    });
    it("test owner stake total is right",async () => {
        const totalStakedBefore = await stakeUACOnBsc.totalStaked();
        const userStakedBefore = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedBefore:",totalStakedBefore);
        console.log("userStakedBefore:",userStakedBefore);

        let tokenId = 4;
        const tx1 = await nft.connect(owner).approve(stakeUACOnBsc.address,tokenId,{
                 gasLimit: 6721975,
        });
        await tx1.wait();
        const tx = await stakeUACOnBsc.connect(owner).stake(tokenId,nft_address,{
                 gasLimit: 6721975,
        });
        await tx.wait();

        const totalStakedAfter = await stakeUACOnBsc.totalStaked();
        const userStakedAfter = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedAfter:",totalStakedAfter);
        console.log("userStakedAfter:",userStakedAfter);

        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,10));
        console.log("owner --> getUserPerDays:",await stakeUACOnBsc.getUserPerDays(owner.address,0,10));

        console.log("User info:",await stakeUACOnBsc.users(owner.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.add(1));
        expect(userStakedAfter).to.equal(userStakedBefore.add(1));

    });

    it("test owner stake batch total is right",async () => {
        const totalStakedBefore = await stakeUACOnBsc.totalStaked();
        const userStakedBefore = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedBefore:",ethers.utils.formatEther(totalStakedBefore));
        console.log("userStakedBefore:",ethers.utils.formatEther(userStakedBefore));

        const countOwner = await nft.balanceOf(owner.address);
        let tokenIds = [ await nft.tokenOfOwnerByIndex(owner.address, 0), await nft.tokenOfOwnerByIndex(owner.address, 1)];
        const tx1 = await nft.connect(owner).setApprovalForAll(stakeUACOnBsc.address,true,{
                 gasLimit: 6721975,
        });
        await tx1.wait();
        const tx = await stakeUACOnBsc.connect(owner).stakeBatch(tokenIds,nft_address,{
                 gasLimit: 6721975,
        });
        await tx.wait();

        const totalStakedAfter = await stakeUACOnBsc.totalStaked();
        const userStakedAfter = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedAfter:",ethers.utils.formatEther(totalStakedAfter));
        console.log("userStakedAfter:",ethers.utils.formatEther(userStakedAfter));

        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,10));
        console.log("owner --> getUserPerDays:",await stakeUACOnBsc.getUserPerDays(owner.address,0,10));

        console.log("User info:",await stakeUACOnBsc.users(owner.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.add(tokenIds.length));
        expect(userStakedAfter).to.equal(userStakedBefore.add(tokenIds.length));
         console.log("staked nfts:",await stakeUACOnBsc.stakedTokens(owner.address));
     })

     it("test user1 stake batch total is right",async () => {
        const totalStakedBefore = await stakeUACOnBsc.totalStaked();
        const userStakedBefore = (await stakeUACOnBsc.users(user1.address)).amount;
        console.log("totalStakedBefore:",totalStakedBefore);
        console.log("userStakedBefore:",userStakedBefore);

        const countOwner = await nft.balanceOf(user1.address);
        let tokenIds = [ await nft.tokenOfOwnerByIndex(user1.address, 0), await nft.tokenOfOwnerByIndex(user1.address, 1)];
        const tx1 = await nft.connect(user1).setApprovalForAll(stakeUACOnBsc.address,true,{
                 gasLimit: 6721975,
        });
        await tx1.wait();
        const tx = await stakeUACOnBsc.connect(user1).stakeBatch(tokenIds,nft_address,{
                 gasLimit: 6721975,
        });
        await tx.wait();

        const totalStakedAfter = await stakeUACOnBsc.totalStaked();
        const userStakedAfter = (await stakeUACOnBsc.users(user1.address)).amount;
        console.log("totalStakedAfter:",totalStakedAfter);
        console.log("userStakedAfter:",userStakedAfter);

        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,10));
        console.log("user1 --> getUserPerDays:",await stakeUACOnBsc.getUserPerDays(user1.address,0,10));

        console.log("User1 info:",await stakeUACOnBsc.users(user1.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.add(tokenIds.length));
        expect(userStakedAfter).to.equal(userStakedBefore.add(tokenIds.length));
        console.log("staked nfts:",await stakeUACOnBsc.stakedTokens(user1.address));
     })


    it("test user1 stake total is right",async () => {
        const totalStakedBefore = await stakeUACOnBsc.totalStaked();
        const userStakedBefore = (await stakeUACOnBsc.users(user1.address)).amount;
        console.log("totalStakedBefore:",totalStakedBefore);
        console.log("userStakedBefore:",userStakedBefore);

        // let amount = ethers.utils.parseEther("100");
        // const tx1 = await nft.connect(user1).approve(stakeUACOnBsc.address,ethers.utils.parseEther("100"));
        // await tx1.wait();
        // const tx = await stakeUACOnBsc.connect(user1).stake(amount,nft_address,{
        //          gasLimit: 1_000_000,
        // });
        // await tx.wait();

        let tokenId = 24;
        const tx1 = await nft.connect(user1).approve(stakeUACOnBsc.address,tokenId,{
                 gasLimit: 6721975,
        });
        await tx1.wait();
        const tx = await stakeUACOnBsc.connect(user1).stake(tokenId,nft_address,{
                 gasLimit: 6721975,
        });
        await tx.wait();


        const totalStakedAfter = await stakeUACOnBsc.totalStaked();
        const userStakedAfter = (await stakeUACOnBsc.users(user1.address)).amount;
        console.log("totalStakedAfter:",totalStakedAfter);
        console.log("userStakedAfter:",userStakedAfter);

        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,10));
        console.log("user1 --> getUserPerDays:",await stakeUACOnBsc.getUserPerDays(user1.address,0,10));

        console.log("User info:",await stakeUACOnBsc.users(user1.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.add(1));
        expect(userStakedAfter).to.equal(userStakedBefore.add(1));

    });


    it("test unstake",async () => {
        const totalStakedBefore = await stakeUACOnBsc.totalStaked();
        const userStakedBefore = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedBefore:",ethers.utils.formatEther(totalStakedBefore));
        console.log("userStakedBefore:",ethers.utils.formatEther(userStakedBefore));

        let tokenId = 50;
        const tx = await stakeUACOnBsc.connect(owner).unStake(tokenId,nft_address,{
                 gasLimit: 1_000_000,
        });
        await tx.wait();

        const totalStakedAfter = await stakeUACOnBsc.totalStaked();
        const userStakedAfter = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedAfter:",ethers.utils.formatEther(totalStakedAfter));
        console.log("userStakedAfter:",ethers.utils.formatEther(userStakedAfter));

        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,10));
        console.log("owner --> getUserPerDays:",await stakeUACOnBsc.getUserPerDays(owner.address,0,10));

        console.log("User info:",await stakeUACOnBsc.users(owner.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.sub(1));
        expect(userStakedAfter).to.equal(userStakedBefore.sub(1));
        console.log("staked nfts:",await stakeUACOnBsc.stakedTokens(owner.address));
       
    });
    it("test unstake batch",async () => {
        const totalStakedBefore = await stakeUACOnBsc.totalStaked();
        const userStakedBefore = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedBefore:",ethers.utils.formatEther(totalStakedBefore));
        console.log("userStakedBefore:",ethers.utils.formatEther(userStakedBefore));
         console.log("before unstaked nfts:",await stakeUACOnBsc.stakedTokens(owner.address));
        let tokenIds = [49,48];
        const tx = await stakeUACOnBsc.connect(owner).unStakeBatch(tokenIds,nft_address,{
                 gasLimit: 1_000_000,
        });
        await tx.wait();

        const totalStakedAfter = await stakeUACOnBsc.totalStaked();
        const userStakedAfter = (await stakeUACOnBsc.users(owner.address)).amount;
        console.log("totalStakedAfter:",ethers.utils.formatEther(totalStakedAfter));
        console.log("userStakedAfter:",ethers.utils.formatEther(userStakedAfter));
       

        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,10));
        console.log("owner --> getUserPerDays:",await stakeUACOnBsc.getUserPerDays(owner.address,0,10));

        console.log("User info:",await stakeUACOnBsc.users(owner.address));
        expect(totalStakedAfter).to.equal(totalStakedBefore.sub(tokenIds.length));
        expect(userStakedAfter).to.equal(userStakedBefore.sub(tokenIds.length));
        console.log("after unstaked nfts:",await stakeUACOnBsc.stakedTokens(owner.address));
       
    });
    it("test calculate reward",async () => {

        // const tx1 = await uac.connect(owner).transfer(stakeUACOnBsc.address,ethers.utils.parseEther("10000000"));
        // await tx1.wait();
        // console.log("StakingUACOnBsc balance is:",await uac.balanceOf(stakeUACOnBsc.address));

        const tx = await stakeUACOnBsc.connect(owner).calculateReward({
            gasLimit: 1_000_000,
        });
        await tx.wait();

        const tx1 = await stakeUACOnBsc.connect(user1).calculateReward({
            gasLimit: 1_000_000,
        });
        await tx1.wait();

        console.log("Owner info:",await stakeUACOnBsc.users(owner.address));
        console.log("User1 info:",await stakeUACOnBsc.users(user1.address));
        console.log("Owner rewardBalance:", ethers.utils.formatEther((await stakeUACOnBsc.users(owner.address)).rewardBalance) );
        console.log("User1 rewardBalance:", ethers.utils.formatEther((await stakeUACOnBsc.users(user1.address)).rewardBalance) );
        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,50));

        console.log("calacute time:",(await stakeUACOnBsc.users(owner.address)).lastCalRewardTime.div(300));


        // console.log("total 490522:",ethers.utils.formatEther((await stakeUACOnBsc.getTotalStakePerDay(490522))) );
        // console.log("total 490523:",ethers.utils.formatEther((await stakeUACOnBsc.getTotalStakePerDay(490523))) );
        // console.log("total 490525:",ethers.utils.formatEther((await stakeUACOnBsc.getTotalStakePerDay(490525))) );
        // console.log("total 490526:",ethers.utils.formatEther((await stakeUACOnBsc.getTotalStakePerDay(490526))) );
        // console.log("total 490537:",ethers.utils.formatEther((await stakeUACOnBsc.getTotalStakePerDay(490537))) );
        // console.log("total 490538:",ethers.utils.formatEther((await stakeUACOnBsc.getTotalStakePerDay(490538))) );

        // console.log("user total 490522:",ethers.utils.formatEther((await stakeUACOnBsc.getUserTotalStakePerDay(490522,owner.address))) );
        // console.log("user total 490523:",ethers.utils.formatEther((await stakeUACOnBsc.getUserTotalStakePerDay(490523,owner.address))) );
        // console.log("user total 490525:",ethers.utils.formatEther((await stakeUACOnBsc.getUserTotalStakePerDay(490525,owner.address))) );
        // console.log("user total 490526:",ethers.utils.formatEther((await stakeUACOnBsc.getUserTotalStakePerDay(490526,owner.address))) );
        // console.log("user total 490537:",ethers.utils.formatEther((await stakeUACOnBsc.getUserTotalStakePerDay(490537,owner.address))) );
        // console.log("user total 490538:",ethers.utils.formatEther((await stakeUACOnBsc.getUserTotalStakePerDay(490538,owner.address))) );

    });

    it("test withdraw reward",async () => {
        const beforeBalance = await uac.balanceOf(owner.address);
        console.log("before balance:",beforeBalance);
        const tx = await stakeUACOnBsc.connect(owner).withDrawReward(uac_address,ethers.utils.parseEther("40"));
        await tx.wait();

        const afterBalance = await uac.balanceOf(owner.address);
        console.log("after balance:",afterBalance);

        expect(afterBalance).to.equal(beforeBalance.add(ethers.utils.parseEther("40")));


    });

    it("search",async () => {
        console.log("User info:",await stakeUACOnBsc.users(owner.address));
        console.log("Owner info:",await stakeUACOnBsc.users(owner.address));
        console.log("User1 info:",await stakeUACOnBsc.users(user1.address));
        console.log("Owner rewardBalance:", ethers.utils.formatEther((await stakeUACOnBsc.users(owner.address)).rewardBalance) );
        console.log("User1 rewardBalance:", ethers.utils.formatEther((await stakeUACOnBsc.users(user1.address)).rewardBalance) );
        console.log("getPerDays:",await stakeUACOnBsc.getPerDays(0,50));
    });

    it("test Approve",async () => {
        let tokenIds = 41;
        const tx1 = await nft.connect(user2).approve(stakeUACOnBsc.address,tokenIds,{
                 gasLimit: 6721975,
        });

        await tx1.wait();

        console.log("is approved",await nft.connect(user2).getApproved(tokenIds));

    });

     it("test ApproveAll",async () => {
       
        // let tokenIds = 42;
        // console.log("is approved",await nft.connect(user2).getApproved(tokenIds));
        // const tx1 = await nft.connect(user2).setApprovalForAll(stakeUACOnBsc.address,true,{
        //          gasLimit: 6721975,
        // });

        // await tx1.wait();

        // console.log("is approved",await nft.connect(user2).getApproved(tokenIds));
        console.log("is approved all",await nft.connect(user2).isApprovedForAll(user2.address,stakeUACOnBsc.address));

    });





});



/**
 

npx hardhat test ./test/uacbsc_stake/StakeUACOnBsc.test.ts --network ganache --grep "test calculate reward"

npx hardhat test ./test/uacbsc_stake/StakeUACOnBsc.test.ts --network ganache --grep "test owner stake batch total is right"
npx hardhat test ./test/uacbsc_stake/StakeUACOnBsc.test.ts --network ganache --grep "test user1 stake batch total is right"
npx hardhat test ./test/uacbsc_stake/StakeUACOnBsc.test.ts --network ganache --grep "test calculate reward"

npx hardhat test ./test/uacbsc_stake/StakeUACOnBsc.test.ts --network ganache --grep "test Approve"

 */