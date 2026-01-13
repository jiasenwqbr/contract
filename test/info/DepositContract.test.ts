import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { AsiaTelevisionINFONFT,INFONFTSellManage,RecommendationINFO,USDTTest ,
    DepositContract,INFORewardDistribute,INFOErc20 ,IUniswapV2Router02,IUniswapV2Factory,TreasuryInsurancePool} from "../../typechain-types";
import { network } from "hardhat";
import { Signer } from "ethers";
import { info } from "../../typechain-types/contracts";


describe("DepositContract.test",()=>{
    let infor_address = "0x1B9D597997DC0BC1b41786556a48C976866B5B64";
    let usdt_address = "0x43Db2F7e34F8583b2eEd39681bC77C2699f15A6d";
    let infoERC20:INFOErc20;
    let deposit_address = "0xc4f7F567838918610D4481cF875495Da241A352c";
    let depositContract:DepositContract;
    let usdt:USDTTest;
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    const recommandContractAddress = "0xe1fE7Ff080f842D6cb25a820FBb2db6F082fa87E";
    let recommend:RecommendationINFO;
    let iNFORewardDistributeAddress = "0xFd5577f62435Cf6c721461B7fE6cF73eBEc754cD";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    let swapRouter:IUniswapV2Router02;
    let factoryAddress:any;
    let factory:IUniswapV2Factory;
    let wbnb:any;
    const depositAllocation = [
        "0x1375E91522Cbc110d6844c1187610869373D9ca4",
        "0xc36268C3Fe6d574A329Ec0676031b6dFe407a7e2",
        "0x6eE5B70cf3652678134e6609C98892FDBA2262Dc",
        "0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10"];
    const depositAllocationRatio = [500,350,100,50];
    let lpReceiveAddress :any;
    let treasurePoolAddress = "0x886cEFa55C7E8F3F0E07a67Ca0aC841240580002";
    let treasurePool:TreasuryInsurancePool;
 
    beforeEach(async () => {
        [owner,user1,user2,user3] = await ethers.getSigners();
        infoERC20 = await ethers.getContractAt("INFOErc20",infor_address) as INFOErc20;
        depositContract = await ethers.getContractAt("DepositContract",deposit_address) as DepositContract;
        usdt = await ethers.getContractAt("USDTTest",usdt_address) as USDTTest;
        recommend = await ethers.getContractAt("RecommendationINFO",recommandContractAddress) as RecommendationINFO;
        swapRouter = await ethers.getContractAt("IUniswapV2Router02",swapRouterAddress) as IUniswapV2Router02;
        factoryAddress = await swapRouter.factory();
        factory = await ethers.getContractAt("IUniswapV2Factory",factoryAddress) as IUniswapV2Factory;
        wbnb = await swapRouter.WETH();

        lpReceiveAddress = await depositContract.lpReceiverAddress();

        treasurePool = await ethers.getContractAt("TreasuryInsurancePool",treasurePoolAddress) as TreasuryInsurancePool;



    });

    it("test deposit",async () => {
        
        console.log("paras",await depositContract.getParams());
        console.log("=================================  before deposit  ==============================");
        console.log("before usdt balace of owner:",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));

        // console.log("#########  before   usdt/wbnb     #########");
        // const usdt_bnb_pair_address = await factory.getPair(usdt_address,wbnb);
        // console.log("usdt/wbnb pair address:",usdt_bnb_pair_address);

        // const usdt_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",usdt_bnb_pair_address);
        // const reserves = await usdt_bnb_Pair.getReserves();
        // console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reserves[0].toString()), ethers.utils.formatEther(reserves[1].toString()));
        // const lpBanlanceBig = await usdt_bnb_Pair.balanceOf(owner.address);
        // const lpBalance = ethers.utils.formatEther(lpBanlanceBig);
        // console.log("lpBalance:", lpBalance);

        console.log("#########  before  info/wbnb     #########");
        const info_bnb_Pair_address =  await factory.getPair(infor_address,wbnb);
        console.log("info/wbnb pair address:",info_bnb_Pair_address);
        const info_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",info_bnb_Pair_address);
        const reserve2 = await info_bnb_Pair.getReserves();
        console.log("info/wbnb before Reserves:", ethers.utils.formatEther(reserve2[0].toString()), ethers.utils.formatEther(reserve2[1].toString()));
        const lpBalance2Big = await info_bnb_Pair.balanceOf(owner.address);
        const lpBalance2 = ethers.utils.formatEther(lpBalance2Big);
        console.log("lpBalance:", lpBalance2);
        const lpReceiveBalanceBig = await info_bnb_Pair.balanceOf(lpReceiveAddress);
        const lpReceiveBalance = ethers.utils.formatEther(lpReceiveBalanceBig);
        console.log("lpReceiveBalance:", lpReceiveBalance,"   lpreceiver:",lpReceiveAddress);

        console.log("#########  before   balance of receiver    #########");
        const receiverBalance0 = await ethers.provider.getBalance(depositAllocation[0]);
        console.log("receiverBalance0 bnb:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance0));
        const receiverBalance1 = await ethers.provider.getBalance(depositAllocation[1]);
        console.log("receiverBalance1 bnb:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance1));
        const receiverBalance2 = await ethers.provider.getBalance(depositAllocation[2]);
        console.log("receiverBalance3 bnb:", depositAllocation[2]," balance:",ethers.utils.formatEther(receiverBalance2));
        const receiverBalance3 = await ethers.provider.getBalance(depositAllocation[3]);
        console.log("receiverBalance3 bnb:", depositAllocation[3]," balance:",ethers.utils.formatEther(receiverBalance3));
        const tx00 = await  infoERC20.setExcludeFee(owner.address,true);
        await tx00.wait();

        // const tx0001 = await await infoERC20.setExcludeFee(deposit_address,true);
        // await tx0001.wait();
        // const tx0003 = await await infoERC20.setExcludeFee(infor_address,true);
        // await tx0003.wait();

        const tx0004 = await depositContract.connect(owner).addSalseQuota(infor_address,ethers.utils.parseEther("100000000000000"));
        await tx0004.wait();

        const tx0005 = await depositContract.connect(owner).addSalseQuota(deposit_address,ethers.utils.parseEther("100000000000000"));
        await tx0005.wait();

        // const tx0006 = await depositContract.connect(owner).addSalseQuota(info_bnb_Pair_address,ethers.utils.parseEther("100000000000000"));
        // await tx0006.wait();
        const buyFeeReceiver0 = (await infoERC20.getBuyFeeReceiver(0))[0];
        const buyFeeReceiver1 = (await infoERC20.getBuyFeeReceiver(1))[0];
        const buyFeeReceiver2 = (await infoERC20.getBuyFeeReceiver(2))[0];
        const buyFeeReceiver3 = (await infoERC20.getBuyFeeReceiver(3))[0];

        console.log("buyFeeReceiver0:",buyFeeReceiver0);
        console.log("buyFeeReceiver1:",buyFeeReceiver1);
        console.log("buyFeeReceiver2:",buyFeeReceiver2);
        console.log("buyFeeReceiver3:",buyFeeReceiver3);
        console.log("user1 address:",user1.address);
        console.log("deposit_address address:",deposit_address);
        console.log("user2 address:",user2.address);
        console.log("user3 address:",user3.address);

        // info balance
        const buyFeeReceiver0INFOBefore = await infoERC20.balanceOf(buyFeeReceiver0);
        const buyFeeReceiver1INFOBefore = await infoERC20.balanceOf(buyFeeReceiver1);
        const buyFeeReceiver2INFOBefore = await infoERC20.balanceOf(buyFeeReceiver2);
        const buyFeeReceiver3INFOBefore = await infoERC20.balanceOf(buyFeeReceiver3);

        console.log("buyFeeReceiver0Before info:",buyFeeReceiver0INFOBefore);
        console.log("buyFeeReceiver1Before info:",buyFeeReceiver1INFOBefore);
        console.log("buyFeeReceiver2Before info:",buyFeeReceiver2INFOBefore);
        console.log("buyFeeReceiver3Before info:",buyFeeReceiver3INFOBefore);
       

        // bnb balance

        const buyFeeReceiver0BNBBefore = await ethers.provider.getBalance(buyFeeReceiver0);
        const buyFeeReceiver1BNBBefore = await ethers.provider.getBalance(buyFeeReceiver1);
        const buyFeeReceiver2BNBBefore = await ethers.provider.getBalance(buyFeeReceiver2);
        const buyFeeReceiver3BNBBefore = await ethers.provider.getBalance(buyFeeReceiver3);

        console.log("buyFeeReceiver0BNBBefore bnb:",buyFeeReceiver0BNBBefore);
        console.log("buyFeeReceiver1BNBBefore bnb:",buyFeeReceiver1BNBBefore);
        console.log("buyFeeReceiver2BNBBefore bnb:",buyFeeReceiver2BNBBefore);
        console.log("buyFeeReceiver3BNBBefore bnb:",buyFeeReceiver3BNBBefore);


        const sellFeeReceiver0 = (await infoERC20.getSellFeeReceiver(0))[0];
        const sellFeeReceiver1 = (await infoERC20.getSellFeeReceiver(1))[0];
        const sellFeeReceiver2 = (await infoERC20.getSellFeeReceiver(2))[0];
        const sellFeeReceiver3 = (await infoERC20.getSellFeeReceiver(3))[0];

        const sellFeeReceiver0INFOBalance = await infoERC20.balanceOf(sellFeeReceiver0);
        const sellFeeReceiver1INFOBalance = await infoERC20.balanceOf(sellFeeReceiver1);
        const sellFeeReceiver2INFOBalance = await infoERC20.balanceOf(sellFeeReceiver2);
        const sellFeeReceiver3INFOBalance = await infoERC20.balanceOf(sellFeeReceiver3);

        const sellFeeReceiver0BNBBalance = await ethers.provider.getBalance(sellFeeReceiver0);
        const sellFeeReceiver1BNBBalance = await ethers.provider.getBalance(sellFeeReceiver1);
        const sellFeeReceiver2BNBBalance = await ethers.provider.getBalance(sellFeeReceiver2);
        const sellFeeReceiver3BNBBalance = await ethers.provider.getBalance(sellFeeReceiver3);

        console.log("sellFeeReceiver0INFOBalance before:",sellFeeReceiver0INFOBalance);
        console.log("sellFeeReceiver1INFOBalance before:",sellFeeReceiver1INFOBalance);
        console.log("sellFeeReceiver2INFOBalance before:",sellFeeReceiver2INFOBalance);
        console.log("sellFeeReceiver3INFOBalance before:",sellFeeReceiver3INFOBalance);

        console.log("sellFeeReceiver0BNBBalance before:",sellFeeReceiver0BNBBalance);
        console.log("sellFeeReceiver1BNBBalance before:",sellFeeReceiver1BNBBalance);
        console.log("sellFeeReceiver2BNBBalance before:",sellFeeReceiver2BNBBalance);
        console.log("sellFeeReceiver3BNBBalance before:",sellFeeReceiver3BNBBalance);


       
       
       
        
        const tx0 = await usdt.connect(owner).approve(deposit_address,ethers.utils.parseEther("100"));
        await tx0.wait();
        const tx =  await depositContract.connect(owner).deposit(usdt_address,ethers.utils.parseEther("100"),ethers.utils.parseEther("100"));
       
        try {
            const resp =  await tx.wait();
            console.log("txhash:",resp.transactionHash);
        } catch (err) {
            console.error(err); 
        }
                

        

        console.log("=================================  after deposit  ==============================");
        // console.log("#########  after   usdt/wbnb     #########");
        // const reservesAfter = await usdt_bnb_Pair.getReserves();
        // console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reservesAfter[0].toString()), ethers.utils.formatEther(reservesAfter[1].toString()));
        // const lpBalanceAfterBig = await usdt_bnb_Pair.balanceOf(owner.address);
        // const lpBalanceAfter = ethers.utils.formatEther(lpBalanceAfterBig);
        // console.log("lpBalance:", lpBalance);

        // console.log("usdt/wbnb lpbalance of owner increasement:",ethers.utils.formatEther(lpBalanceAfterBig.sub(lpBanlanceBig)));
        console.log("#########  after  info/wbnb     #########");
        const reserveAfter = await info_bnb_Pair.getReserves();
        console.log("info/wbnb  after Reserves:", ethers.utils.formatEther(reserveAfter[0].toString()), ethers.utils.formatEther(reserveAfter[1].toString()));
        const lpBalance2AfterBig = await info_bnb_Pair.balanceOf(owner.address);
        const lpBalance2After = ethers.utils.formatEther(lpBalance2AfterBig);
        console.log("lpBalance:", lpBalance2After);
        console.log("info/wbnb lpbalance of owner increasement:",ethers.utils.formatEther(lpBalance2AfterBig.sub(lpBalance2Big)));
        const lpReceiveBalanceAfterBig = await info_bnb_Pair.balanceOf(lpReceiveAddress);
        const lpReceiveBalanceAfter = ethers.utils.formatEther(lpReceiveBalanceAfterBig);
        console.log("lpReceiveBalance:", lpReceiveBalanceAfter,"   lpreceiver:",lpReceiveAddress);

        console.log("info/wbnb lpReceiveBalance  increasement:",ethers.utils.formatEther(lpReceiveBalanceAfterBig.sub(lpReceiveBalanceBig)));


        const receiverBalance0After = await ethers.provider.getBalance(depositAllocation[0]);
        console.log("receiverBalance0 bnb:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance0After));
        const receiverBalance1After = await ethers.provider.getBalance(depositAllocation[1]);
        console.log("receiverBalance1:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance1After));
        const receiverBalance2After = await ethers.provider.getBalance(depositAllocation[2]);
        console.log("receiverBalance3:", depositAllocation[2]," balance:",ethers.utils.formatEther(receiverBalance2After));
        const receiverBalance3After = await ethers.provider.getBalance(depositAllocation[3]);
        console.log("receiverBalance3:", depositAllocation[3]," balance:",ethers.utils.formatEther(receiverBalance3After));
        
        console.log("The bnb balance incresment of receiver0:",receiverBalance0After.sub(receiverBalance0));
        console.log("The bnb balance incresment of receiver1:",receiverBalance1After.sub(receiverBalance1));
        console.log("The bnb balance incresment of receiver2:",receiverBalance2After.sub(receiverBalance2));
        console.log("The bnb balance incresment of receiver3:",receiverBalance3After.sub(receiverBalance3));

        const sellFeeReceiver0INFOBalanceAfter = await infoERC20.balanceOf(sellFeeReceiver0);
        const sellFeeReceiver1INFOBalanceAfter = await infoERC20.balanceOf(sellFeeReceiver1);
        const sellFeeReceiver2INFOBalanceAfter = await infoERC20.balanceOf(sellFeeReceiver2);
        const sellFeeReceiver3INFOBalanceAfter = await infoERC20.balanceOf(sellFeeReceiver3);

        const sellFeeReceiver0BNBBalanceAfter = await ethers.provider.getBalance(sellFeeReceiver0);
        const sellFeeReceiver1BNBBalanceAfter = await ethers.provider.getBalance(sellFeeReceiver1);
        const sellFeeReceiver2BNBBalanceAfter = await ethers.provider.getBalance(sellFeeReceiver2);
        const sellFeeReceiver3BNBBalanceAfter = await ethers.provider.getBalance(sellFeeReceiver3);

        console.log("sellFeeReceiver0INFOBalanceAfter After:",sellFeeReceiver0INFOBalanceAfter);
        console.log("sellFeeReceiver1INFOBalanceAfter After:",sellFeeReceiver1INFOBalanceAfter);
        console.log("sellFeeReceiver2INFOBalanceAfter After:",sellFeeReceiver2INFOBalanceAfter);
        console.log("sellFeeReceiver3INFOBalanceAfter After:",sellFeeReceiver3INFOBalanceAfter);

        console.log("sellFeeReceiver0BNBBalanceAfter After:",sellFeeReceiver0BNBBalanceAfter);
        console.log("sellFeeReceiver1BNBBalanceAfter After:",sellFeeReceiver1BNBBalanceAfter);
        console.log("sellFeeReceiver2BNBBalanceAfter After:",sellFeeReceiver2BNBBalanceAfter);
        console.log("sellFeeReceiver3BNBBalanceAfter After:",sellFeeReceiver3BNBBalanceAfter);


        




       // info balance
        const buyFeeReceiver0INFAfter = await infoERC20.balanceOf(buyFeeReceiver0);
        const buyFeeReceiver1INFAfter = await infoERC20.balanceOf(buyFeeReceiver1);
        const buyFeeReceiver2INFAfter = await infoERC20.balanceOf(buyFeeReceiver2);
        const buyFeeReceiver3INFAfter = await infoERC20.balanceOf(buyFeeReceiver3);

        console.log("buyFeeReceiver0INFAfter info:",buyFeeReceiver0INFAfter);
        console.log("buyFeeReceiver1INFAfter info:",buyFeeReceiver1INFAfter);
        console.log("buyFeeReceiver2INFAfter info:",buyFeeReceiver2INFAfter);
        console.log("buyFeeReceiver3INFAfter info:",buyFeeReceiver3INFAfter);
       

        // bnb balance

        const buyFeeReceiver0BNBAfter = await ethers.provider.getBalance(buyFeeReceiver0);
        const buyFeeReceiver1BNBAfter = await ethers.provider.getBalance(buyFeeReceiver1);
        const buyFeeReceiver2BNBAfter = await ethers.provider.getBalance(buyFeeReceiver2);
        const buyFeeReceiver3BNBAfter = await ethers.provider.getBalance(buyFeeReceiver3);

        console.log("buyFeeReceiver0BNBAfter bnb:",buyFeeReceiver0BNBAfter);
        console.log("buyFeeReceiver1BNBAfter bnb:",buyFeeReceiver1BNBAfter);
        console.log("buyFeeReceiver2BNBAfter bnb:",buyFeeReceiver2BNBAfter);
        console.log("buyFeeReceiver3BNBAfter bnb:",buyFeeReceiver3BNBAfter);

        // info the increasement of buy receiver
        console.log("buyFeeReceiver0  info increasement:",buyFeeReceiver0INFAfter.sub(buyFeeReceiver0INFOBefore));
        console.log("buyFeeReceiver1  info increasement:",buyFeeReceiver1INFAfter.sub(buyFeeReceiver1INFOBefore));
        console.log("buyFeeReceiver2  info increasement:",buyFeeReceiver2INFAfter.sub(buyFeeReceiver2INFOBefore));
        console.log("buyFeeReceiver3  info increasement:",buyFeeReceiver3INFAfter.sub(buyFeeReceiver3INFOBefore));

        // bnb the increment of buy receiver 
        console.log("buyFeeReceiver0  bnb  increasement:",buyFeeReceiver0BNBAfter.sub(buyFeeReceiver0BNBBefore));
        console.log("buyFeeReceiver1  bnb  increasement:",buyFeeReceiver1BNBAfter.sub(buyFeeReceiver1BNBBefore));
        console.log("buyFeeReceiver2  bnb  increasement:",buyFeeReceiver2BNBAfter.sub(buyFeeReceiver2BNBBefore));
        console.log("buyFeeReceiver3  bnb  increasement:",buyFeeReceiver3BNBAfter.sub(buyFeeReceiver3BNBBefore));

        console.log("sellFeeReceiver0INFOBalance increasement:",sellFeeReceiver0INFOBalanceAfter.sub(sellFeeReceiver0INFOBalance));
        console.log("sellFeeReceiver1INFOBalance increasement:",sellFeeReceiver1INFOBalanceAfter.sub(sellFeeReceiver1INFOBalance));
        console.log("sellFeeReceiver2INFOBalance increasement:",sellFeeReceiver2INFOBalanceAfter.sub(sellFeeReceiver2INFOBalance));
        console.log("sellFeeReceiver3INFOBalance increasement:",sellFeeReceiver3INFOBalanceAfter.sub(sellFeeReceiver3INFOBalance));

        console.log("sellFeeReceiver0BNBBalance increasement:",sellFeeReceiver0BNBBalanceAfter.sub(sellFeeReceiver0BNBBalance));
        console.log("sellFeeReceiver1BNBBalance increasement:",sellFeeReceiver1BNBBalanceAfter.sub(sellFeeReceiver1BNBBalance));
        console.log("sellFeeReceiver2BNBBalance increasement:",sellFeeReceiver2BNBBalanceAfter.sub(sellFeeReceiver2BNBBalance));
        console.log("sellFeeReceiver3BNBBalance increasement:",sellFeeReceiver3BNBBalanceAfter.sub(sellFeeReceiver3BNBBalance));
       

    });
    it ("after deposit",async () => {
    });

    it("INFO transfer",async () => {
        // const tx4 = await infoERC20.connect(owner).transfer(iNFORewardDistributeAddress,ethers.utils.parseEther("10000"));
        // await tx4.wait();
        // console.log("balance of reward:",ethers.utils.formatEther(await infoERC20.balanceOf(iNFORewardDistributeAddress)) );

        const tx5 = await infoERC20.connect(owner).transfer("0x1a7844678B0E9aEb4133bCf35ae1f56B9353e481",ethers.utils.parseEther("100000"));
        await tx5.wait(2);
        console.log("balance:",ethers.utils.formatEther(await infoERC20.balanceOf("0x1a7844678B0E9aEb4133bCf35ae1f56B9353e481")) );



    });
    it("get recommend user info",async () => {
        console.log("userInfo:",await recommend.getUserInfo(owner.address));
    });

    it("bind user",async() => {
        // const tx = await recommend.bindRelationShip(user2.address);
        // await tx.wait();

        console.log("user1:",user1.address);
        console.log("user2:",user2.address);
        console.log("user3:",user3.address);


        console.log(await infoERC20.isGlobalWhitelisted(deposit_address));
    });
    it("testss",async ()=> {
        console.log(await depositContract.getParams());
        console.log(await infoERC20.getBuyTradingEnabled());
        const tx00 = await await infoERC20.setExcludeFee(owner.address,true);
        await tx00.wait();

        const tx0001 = await await infoERC20.setExcludeFee(deposit_address,true);
        await tx0001.wait();


        const tx001 = await infoERC20.setExcludeFee(owner.address,true);
        await tx001.wait();
        const tx0 = await infoERC20.connect(owner).approve(deposit_address,ethers.utils.parseEther("100000"));
        await tx0.wait();
        
                
    });

    it("treasurePool",async () => {
        const balanceContract = await ethers.provider.getBalance(treasurePoolAddress);
        console.log("balanceContract:",balanceContract);
        // const tx = await treasurePool.redeemAndBurn();
        // try {
        //     const resp =  await tx.wait();
        //     console.log("txhash:",resp.transactionHash);
        // } catch (err) {
        //     console.error(err); 
        // }
        const balanceContractAfter = await ethers.provider.getBalance(treasurePoolAddress);
        console.log("balanceContractAfter:",balanceContractAfter);

        const x = await treasurePool.balance("0x0000000000000000000000000000000000000000");
        console.log(x);
    });

    it("etherTrans",async () => {
        console.log(ethers.utils.formatEther("94737502311706198855"));
    });

});


/**
 
npx hardhat test ./test/info/DepositContract.test --network bscTest

npx hardhat test ./test/info/DepositContract.test --network bscTest --grep "test deposit"

npx hardhat test ./test/info/DepositContract.test --network bscTest --grep "testss"

npx hardhat test ./test/info/DepositContract.test --network bscTest --grep "INFO transfer"

npx hardhat test ./test/info/DepositContract.test --network bscTest --grep "treasurePool"

npx hardhat test ./test/info/DepositContract.test --network bscTest --grep "etherTrans"
 
*/
