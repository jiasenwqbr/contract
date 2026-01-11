import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,INFOErc20,DepositContract,EcoMineralPool,TreasuryInsurancePool,S1Pool,GenesisNodeDistrictDividendPool} from  "../../../typechain-types";

async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    // 50%
    const factory1 = await ethers.getContractFactory('EcoMineralPool');
    // const ecoMineralPool =  (await upgrades.deployProxy(factory1,[],{kind:'uups'})) as EcoMineralPool;
    const ecoMineralPool = await upgrades.upgradeProxy('0x1375E91522Cbc110d6844c1187610869373D9ca4', factory1, { kind: 'uups' });
    await ecoMineralPool.deployed();
    console.log("EcoMineralPool(50%) address is:",ecoMineralPool.address);

    const factory2 = await ethers.getContractFactory('TreasuryInsurancePool');
    // const treasuryInsurancePool =  (await upgrades.deployProxy(factory2,[],{kind:'uups'})) as TreasuryInsurancePool;
    const treasuryInsurancePool = await upgrades.upgradeProxy('0xc36268C3Fe6d574A329Ec0676031b6dFe407a7e2', factory2, { kind: 'uups' });
    await treasuryInsurancePool.deployed();
    console.log("TreasuryInsurancePool(35%) address is:",treasuryInsurancePool.address);

    const tx21 = await treasuryInsurancePool.setRedeemRatio(150);
    await tx21.wait();
    const tx2 = await treasuryInsurancePool.setRedeemToAddress(user2.address);
    await tx2.wait();


    const factory3 = await ethers.getContractFactory('S1Pool');
    // const s1Pool =  (await upgrades.deployProxy(factory3,[],{kind:'uups'})) as S1Pool;
    const s1Pool = await upgrades.upgradeProxy('0x6eE5B70cf3652678134e6609C98892FDBA2262Dc', factory3, { kind: 'uups' });
    await s1Pool.deployed();
    console.log("S1Pool(10%) address is:",s1Pool.address);

    const factory4 = await ethers.getContractFactory('GenesisNodeDistrictDividendPool');
    // const genesisNodeDistrictDividendPool =  (await upgrades.deployProxy(factory4,[],{kind:'uups'})) as GenesisNodeDistrictDividendPool;
    const genesisNodeDistrictDividendPool = await upgrades.upgradeProxy('0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10', factory3, { kind: 'uups' });
    await genesisNodeDistrictDividendPool.deployed();
    console.log("GenesisNodeDistrictDividendPool(5%) address is:",genesisNodeDistrictDividendPool.address);




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
S1Pool(10%) address is: 0x6eE5B70cf3652678134e6609C98892FDBA2262Dc
GenesisNodeDistrictDividendPool(5%) address is: 0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10

*/