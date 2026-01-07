import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,INFOErc20,DepositContract} from  "../../../typechain-types";

async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uusdt_address = "0x640f818613eBc0534BFA62Ff189996bc2bf26003";
    const infoAddress = "0x11d6ea3e3b363A9888859300EDF88533AE078e5b";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const depositAllocation = [
        "0x1375E91522Cbc110d6844c1187610869373D9ca4",
        "0xc36268C3Fe6d574A329Ec0676031b6dFe407a7e2",
        "0x6eE5B70cf3652678134e6609C98892FDBA2262Dc",
        "0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10"];
    const depositAllocationRatio = [500,350,100,50];

    // deploy
    const args = [uusdt_address,infoAddress,swapRouterAddress,depositAllocation,depositAllocationRatio];
    const factory = await ethers.getContractFactory('DepositContract');
    const depositContract =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as DepositContract;
    // const depositContract = await upgrades.upgradeProxy('0x4d25E8a0C8eAaB664aFd9186E2D4B13bc81d1A1c', factory, { kind: 'uups' });
    await depositContract.deployed();
    console.log("DepositContract address is:",depositContract.address);

    // set INFO_ROLE
    const tx1 = await depositContract.grantRole(await depositContract.INFO_ROLE(),infoAddress);
    await tx1.wait();

    const tx11 = await depositContract.setPara( uusdt_address,infoAddress,swapRouterAddress);
    await tx11.wait();

    // set INFOErc20 contract 
    const infoErc20 = await ethers.getContractAt("INFOErc20",infoAddress);
    const tx = await infoErc20.setDepositContract(depositContract.address);
    await tx.wait();

    // set INFOErc20 fee receiver
   const tx2 = await infoErc20.setBuyFeeReceivers([
    user1.address,depositContract.address,user2.address,user2.address
   ],[
    20,160,10,10
   ]);
   await tx2.wait();

   const tx3 = await infoErc20.setSellFeeReceivers([
    user1.address,depositContract.address,user2.address,user2.address
   ],[
    20,160,10,10
   ]);
   await tx3.wait();


    

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/bsctest/07deployDepositContract_bsctest.ts --network bscTest

DepositContract address is: 0xDaD46aE3E421cBAE5539C56DeE6061b1709115a4

*/