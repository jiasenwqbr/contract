import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,INFOErc20,DepositContract,EcoMineralPool,TreasuryInsurancePool,S1Pool,GenesisNodeDistrictDividendPool} from  "../../../typechain-types";

async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    // 50%
    // const factory1 = await ethers.getContractFactory('EcoMineralPool');
    // // const ecoMineralPool =  (await upgrades.deployProxy(factory1,[],{kind:'uups'})) as EcoMineralPool;
    // const ecoMineralPool = await upgrades.upgradeProxy('0x1375E91522Cbc110d6844c1187610869373D9ca4', factory1, { kind: 'uups' });
    // await ecoMineralPool.deployed();
    // console.log("EcoMineralPool(50%) address is:",ecoMineralPool.address);

    // #################   deploy TreasuryInsurancePool
    const info_address = "0x1B9D597997DC0BC1b41786556a48C976866B5B64";
    const router_Address = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const depositContractAddress = "0xc4f7F567838918610D4481cF875495Da241A352c";
    // const info_address = "0x462017B39ed4507585a92391D9c13b6031121c2f";
    // const router_Address = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    // const depositContractAddress = "0x0146e0D7A0d66b03D0658863317a09DC5588c1Ff";
    const args = [info_address,router_Address];
    const factory2 = await ethers.getContractFactory('TreasuryInsurancePool');
    // const treasuryInsurancePool =  (await upgrades.deployProxy(factory2,args,{kind:'uups'})) as TreasuryInsurancePool;
    const treasuryInsurancePool = await upgrades.upgradeProxy('0x886cEFa55C7E8F3F0E07a67Ca0aC841240580002', factory2, { kind: 'uups' });
    await treasuryInsurancePool.deployed();
    console.log("TreasuryInsurancePool(35%) address is:",treasuryInsurancePool.address);

    const tx21 = await treasuryInsurancePool.setRedeemRatio(150);
    await tx21.wait();
    const tx2 = await treasuryInsurancePool.setRedeemToAddress("0x000000000000000000000000000000000000dEaD");
    await tx2.wait();

    const tx22 = await treasuryInsurancePool.connect(owner).grantRole(await treasuryInsurancePool.MANAGE_ROLE(),"0xcdDa4F2ADD39Db9F64Ee43e7A825655e5c865FFd");
    await tx22.wait();
    const tx23 = await treasuryInsurancePool.setDepositContractAddress(depositContractAddress);
    await tx23.wait();
    const tx24 = await treasuryInsurancePool.setInfoAddress(info_address);
    await tx24.wait();

    const depositContract = await ethers.getContractAt("DepositContract",depositContractAddress);
    const tx33 = await depositContract.grantRole(await depositContract.MANAGE_ROLE(),treasuryInsurancePool.address);
    await tx33.wait();
    const tx44 = await depositContract.setRedeenAddress(treasuryInsurancePool.address);
    await tx44.wait();


    // const factory3 = await ethers.getContractFactory('S1Pool');
    // // const s1Pool =  (await upgrades.deployProxy(factory3,[],{kind:'uups'})) as S1Pool;
    // const s1Pool = await upgrades.upgradeProxy('0x6eE5B70cf3652678134e6609C98892FDBA2262Dc', factory3, { kind: 'uups' });
    // await s1Pool.deployed();
    // console.log("S1Pool(10%) address is:",s1Pool.address);

    // const factory4 = await ethers.getContractFactory('GenesisNodeDistrictDividendPool');
    // // const genesisNodeDistrictDividendPool =  (await upgrades.deployProxy(factory4,[],{kind:'uups'})) as GenesisNodeDistrictDividendPool;
    // const genesisNodeDistrictDividendPool = await upgrades.upgradeProxy('0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10', factory3, { kind: 'uups' });
    // await genesisNodeDistrictDividendPool.deployed();
    // console.log("GenesisNodeDistrictDividendPool(5%) address is:",genesisNodeDistrictDividendPool.address);




}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/bsctest/06deployPoolContracts_bsctest.ts --network bscTest

EcoMineralPool(50%) address is: 0x1375E91522Cbc110d6844c1187610869373D9ca4
TreasuryInsurancePool(35%) address is: 0xc36268C3Fe6d574A329Ec0676031b6dFe407a7e2

TreasuryInsurancePool(35%) address is: 0x886cEFa55C7E8F3F0E07a67Ca0aC841240580002

S1Pool(10%) address is: 0x6eE5B70cf3652678134e6609C98892FDBA2262Dc
GenesisNodeDistrictDividendPool(5%) address is: 0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10

*/