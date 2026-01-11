import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { AsiaTelevisionINFONFT,INFONFTSellManage,RecommendationINFO,USDTTest ,
    DepositContract,INFORewardDistribute,INFOErc20 ,IUniswapV2Router02,IUniswapV2Factory} from "../../typechain-types";
import { network } from "hardhat";
import { Signer } from "ethers";
import { info } from "../../typechain-types/contracts";


describe("DepositContract.test",()=>{
    let infor_address = "0xC67ACDfe21cf8cefb210941f919ab1bFb3904D2b";
    let usdt_address = "0x75A79414fcae320Ac6B063430239654b1a23A7Dd";
    let infoERC20:INFOErc20;
    let deposit_address = "0x806Fd9c7e906F97627559f3F789fFE9B0b4e61a6";
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

    });

    it("test deposit",async () => {
        
        console.log("paras",await depositContract.getParams());
        console.log("=================================  before deposit  ==============================");
        console.log("before usdt balace of owner:",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));

        console.log("#########  before   usdt/wbnb     #########");
        const usdt_bnb_pair_address = await factory.getPair(usdt_address,wbnb);
        console.log("usdt/wbnb pair address:",usdt_bnb_pair_address);

        const usdt_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",usdt_bnb_pair_address);
        const reserves = await usdt_bnb_Pair.getReserves();
        console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reserves[0].toString()), ethers.utils.formatEther(reserves[1].toString()));
        const lpBanlanceBig = await usdt_bnb_Pair.balanceOf(owner.address);
        const lpBalance = ethers.utils.formatEther(lpBanlanceBig);
        console.log("lpBalance:", lpBalance);

        console.log("#########  before  info/wbnb     #########");
        const info_bnb_Pair_address =  await factory.getPair(infor_address,wbnb);
        console.log("info/wbnb pair address:",info_bnb_Pair_address);
        const info_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",info_bnb_Pair_address);
        const reserve2 = await info_bnb_Pair.getReserves();
        console.log("info/wbnb  Reserves:", ethers.utils.formatEther(reserve2[0].toString()), ethers.utils.formatEther(reserve2[1].toString()));
        const lpBalance2Big = await info_bnb_Pair.balanceOf(owner.address);
        const lpBalance2 = ethers.utils.formatEther(lpBalance2Big);
        console.log("lpBalance:", lpBalance2);
        const lpReceiveBalanceBig = await info_bnb_Pair.balanceOf(lpReceiveAddress);
        const lpReceiveBalance = ethers.utils.formatEther(lpReceiveBalanceBig);
        console.log("lpReceiveBalance:", lpReceiveBalance);

        console.log("#########  before   balance of receiver    #########");
        const receiverBalance0Big = await infoERC20.balanceOf(depositAllocation[0]);
        console.log("receiverBalance0:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance0Big));
        const receiverBalance1 = await ethers.provider.getBalance(depositAllocation[1]);
        console.log("receiverBalance1:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance1));
        const receiverBalance2 = await ethers.provider.getBalance(depositAllocation[2]);
        console.log("receiverBalance3:", depositAllocation[2]," balance:",ethers.utils.formatEther(receiverBalance2));
        const receiverBalance3 = await ethers.provider.getBalance(depositAllocation[3]);
        console.log("receiverBalance3:", depositAllocation[3]," balance:",ethers.utils.formatEther(receiverBalance3));
        const tx00 = await await infoERC20.setExcludeFee(owner.address,true);
        await tx00.wait();

        const tx0001 = await await infoERC20.setExcludeFee(deposit_address,true);
        await tx0001.wait();
        const tx0003 = await await infoERC20.setExcludeFee(infor_address,true);
        await tx0003.wait();

        const tx0004 = await depositContract.connect(owner).addSalseQuota(infor_address,ethers.utils.parseEther("100000000000000"));
        await tx0004.wait();

        const tx0005 = await depositContract.connect(owner).addSalseQuota(deposit_address,ethers.utils.parseEther("100000000000000"));
        await tx0005.wait();

        const tx0006 = await depositContract.connect(owner).addSalseQuota(info_bnb_Pair_address,ethers.utils.parseEther("100000000000000"));
        await tx0006.wait();
       
       
        
        const tx0 = await usdt.connect(owner).approve(deposit_address,ethers.utils.parseEther("100"));
        await tx0.wait();
        const tx =  await depositContract.connect(owner).deposit(usdt_address,ethers.utils.parseEther("100"),ethers.utils.parseEther("100"));
       
            try {
               const resp =  await tx.wait();
               console.log(resp);
            } catch (err) {
                console.error(err); 
            }
                

        // info balance
        const ownerInfoBalanceBefore = await infoERC20.balanceOf(owner.address);
        const user1InfoBalanceBefore = await infoERC20.balanceOf(user1.address);
        const user2InfoBalanceBefore = await infoERC20.balanceOf(user2.address);

        console.log("ownerInfoBalanceBefore:",ownerInfoBalanceBefore);
        console.log("user1InfoBalanceBefore:",user1InfoBalanceBefore);
        console.log("user2InfoBalanceBefore:",user2InfoBalanceBefore);


         console.log("=================================  after deposit  ==============================");
         console.log("#########  after   usdt/wbnb     #########");
        const reservesAfter = await usdt_bnb_Pair.getReserves();
        console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reservesAfter[0].toString()), ethers.utils.formatEther(reservesAfter[1].toString()));
        const lpBalanceAfterBig = await usdt_bnb_Pair.balanceOf(owner.address);
        const lpBalanceAfter = ethers.utils.formatEther(lpBalanceAfterBig);
        console.log("lpBalance:", lpBalance);

        console.log("usdt/wbnb lpbalance of owner increasement:",ethers.utils.formatEther(lpBalanceAfterBig.sub(lpBanlanceBig)));
        console.log("#########  after  info/wbnb     #########");
        const reserveAfter = await info_bnb_Pair.getReserves();
        console.log("info/wbnb  Reserves:", ethers.utils.formatEther(reserveAfter[0].toString()), ethers.utils.formatEther(reserveAfter[1].toString()));
        const lpBalance2AfterBig = await info_bnb_Pair.balanceOf(owner.address);
        const lpBalance2After = ethers.utils.formatEther(lpBalance2AfterBig);
        console.log("lpBalance:", lpBalance2After);
        console.log("info/wbnb lpbalance of owner increasement:",ethers.utils.formatEther(lpBalance2AfterBig.sub(lpBalance2Big)));
        const lpReceiveBalanceAfterBig = await info_bnb_Pair.balanceOf(lpReceiveAddress);
        const lpReceiveBalanceAfter = ethers.utils.formatEther(lpReceiveBalanceAfterBig);
        console.log("lpReceiveBalance:", lpReceiveBalanceAfter);

        console.log("info/wbnb lpReceiveBalance  increasement:",ethers.utils.formatEther(lpReceiveBalanceAfterBig.sub(lpReceiveBalanceBig)));

        console.log("#########  after   balance of receiver    #########");
        const receiverBalance0AfterBig = await infoERC20.balanceOf(depositAllocation[0]);
        console.log("receiverBalance0:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance0AfterBig));
        const receiverBalance1After = await ethers.provider.getBalance(depositAllocation[1]);
        console.log("receiverBalance1After:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance1After));
        const receiverBalance2After = await ethers.provider.getBalance(depositAllocation[2]);
        console.log("receiverBalance2After:", depositAllocation[2]," balance:",ethers.utils.formatEther(receiverBalance2After));
        const receiverBalance3After = await ethers.provider.getBalance(depositAllocation[3]);
        console.log("receiverBalance3After:", depositAllocation[3]," balance:",ethers.utils.formatEther(receiverBalance3After));

        console.log("receiver0 INFO balance increase:",receiverBalance0AfterBig.sub(receiverBalance0Big),"   pase ether:",ethers.utils.formatEther(receiverBalance0AfterBig.sub(receiverBalance0Big)));
        console.log("receiver1 bnb balance increase:",receiverBalance1After.sub(receiverBalance1),"   pase ether:",ethers.utils.formatEther(receiverBalance1After.sub(receiverBalance1)));
        console.log("receiver2 bnb balance increase:",receiverBalance2After.sub(receiverBalance2),"   pase ether:",ethers.utils.formatEther(receiverBalance2After.sub(receiverBalance2)));
        console.log("receiver3 bnb balance increase:",receiverBalance3After.sub(receiverBalance3),"   pase ether:",ethers.utils.formatEther(receiverBalance3After.sub(receiverBalance3)));


       // info balance
        const ownerInfoBalanceAfter = await infoERC20.balanceOf(owner.address);
        const user1InfoBalanceAfter = await infoERC20.balanceOf(user1.address);
        const user2InfoBalanceAfter = await infoERC20.balanceOf(user2.address);

        console.log("ownerInfoBalanceAfter:",ownerInfoBalanceAfter);
        console.log("user1InfoBalanceAfter:",user1InfoBalanceAfter);
        console.log("user2InfoBalanceAfter:",user2InfoBalanceAfter);

        console.log("ownerInfoBalance increase:", ownerInfoBalanceAfter.sub(ownerInfoBalanceBefore));
        console.log("user1InfoBalance increase:",user1InfoBalanceAfter.sub(user1InfoBalanceBefore));
        console.log("user2InfoBalance increase:",user2InfoBalanceAfter.sub(user2InfoBalanceBefore));



        
       

    });
    it ("after deposit",async () => {

        // console.log("=================================  after deposit  ==============================");
        // console.log("after usdt balace of owner:",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));
        //  console.log("#########  after   usdt/wbnb     #########");
        // const usdt_bnb_pair_address = await factory.getPair(usdt_address,wbnb);
        // console.log("usdt/wbnb pair address:",usdt_bnb_pair_address);

        // const usdt_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",usdt_bnb_pair_address);
        // const reserves = await usdt_bnb_Pair.getReserves();
        // console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reserves[0].toString()), ethers.utils.formatEther(reserves[1].toString()));
        // const lpBalance = ethers.utils.formatEther(await usdt_bnb_Pair.balanceOf(owner.address));
        // console.log("lpBalance:", lpBalance);

        // console.log("#########  after  info/wbnb     #########");
        // const info_bnb_Pair_address =  await factory.getPair(usdt_address,wbnb);
        // console.log("info/wbnb pair address:",info_bnb_Pair_address);
        // const info_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",info_bnb_Pair_address);
        // const reserve2 = await info_bnb_Pair.getReserves();
        // console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reserve2[0].toString()), ethers.utils.formatEther(reserve2[1].toString()));
        // const lpBalance2 = ethers.utils.formatEther(await usdt_bnb_Pair.balanceOf(owner.address));
        // console.log("lpBalance:", lpBalance2);

        // console.log("#########  after   balance of receiver    #########");
        // const receiverBalance1 = await ethers.provider.getBalance(depositAllocation[1]);
        // console.log("receiverBalance1:", depositAllocation[1]," balance:",ethers.utils.formatEther(receiverBalance1));
        // const receiverBalance2 = await ethers.provider.getBalance(depositAllocation[2]);
        // console.log("receiverBalance3:", depositAllocation[2]," balance:",ethers.utils.formatEther(receiverBalance2));
        // const receiverBalance3 = await ethers.provider.getBalance(depositAllocation[3]);
        // console.log("receiverBalance3:", depositAllocation[3]," balance:",ethers.utils.formatEther(receiverBalance3));

    });

    it("INFO transfer",async () => {
        // const tx4 = await infoERC20.connect(owner).transfer(iNFORewardDistributeAddress,ethers.utils.parseEther("10000"));
        // await tx4.wait();
        console.log("balance of reward:",ethers.utils.formatEther(await infoERC20.balanceOf(iNFORewardDistributeAddress)) );
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
        const tx =  await depositContract.connect(owner).addLiquidityBNBINFO1(100);
       
            try {
                await tx.wait();
            } catch (err) {
                console.error(err); 
            }
                
    });
});


/**
 
npx hardhat test ./test/info/DepositContract.test --network bscTest

npx hardhat test ./test/info/DepositContract.test --network bscTest --grep "test deposit"

npx hardhat test ./test/info/DepositContract.test --network bscTest --grep "testss"
 
*/
