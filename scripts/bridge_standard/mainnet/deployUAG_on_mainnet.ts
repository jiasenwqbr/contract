import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){
   
   const [owner] = await ethers.getSigners();
    const receiver = '0x2e395365c9d36252268d8997ca0f022431967232';

    const router02_address = '0xDd682E7BE09F596F0D0DEDD53Eb75abffDcd2312';
    const usdt_address = '0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B';
    const wpijs = '0x30FF9d7E86Cbc55E970a6835248b30B21BD1390E';
   
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    const uagFactory = await ethers.getContractFactory("UAGERC20");
    // const uag = await uagFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
    // await uag.deployed();
    // console.log("UAG address is:",uag.address);

    // const tokenA = uag.address;
    // const tokenB = "0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B"; // USDT
    // const factoryAddress = "0x144590c6C9ce4B352943a6BA17F1748aAe0E3BAd"; // PiJFactory
    // const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    // const pairAddress = await factory.getPair(tokenA, tokenB);
    // console.log("UAG/USDT pairAddress is:",pairAddress);


    //  //    手续费
    // const tx = await uag.setBuyFeeReceivers(
    //     ['0x57F6384D434B1613eb80B26B6D74C49909372b11','0xf504551185c4b3ee73e9d96eea06e3fd4210e601'],
    //     [10,10]
    // );
    // await tx.wait();

    // const tx1 = await uag.setSellFeeReceivers(
    //      ['0x57F6384D434B1613eb80B26B6D74C49909372b11','0xf504551185c4b3ee73e9d96eea06e3fd4210e601'],
    //      [10,10]
    // );
    // await tx1.wait();

    // const tx2 = await uag.batchUpdateGlobalWhitelist([owner.address,
    //     '0x466D44EFBf7F1035Feba1F0BdC6fEDE9Bd0729F4',
    //     '0xBDfb7B3cDDd4DE4F36fedFf836D25ED2365B146c'
    // ],true,{
    //     gasLimit:12000000
    // });
    // await tx2.wait();




     // 开关
    const tokenContract = await ethers.getContractAt('UAGERC20','0xe6Abc3Efd6818f20143D7587dCac5cb336F93640');
    // // 币对是不是开放
    // const tx21 = await  tokenContract.setPairsEnabledStatus('0x577B0C2c921b75486ed87Ef33f517eab9102E15e',true);
    // await tx21.wait();
    // // // 交易是否公开
    // const tx22 = await tokenContract.updateTradingEnabled(false);
    // await tx22.wait();
    // 交易是否开启全局交易
    // const tx23 = await tokenContract.setTradeToPublic(true);
    // await tx23.wait();
    // // 批量更新全局白名单
    // const tx24 = await tokenContract.batchUpdateGlobalWhitelist([
    //     '0xb98E2E18259057076b3170c078F361978768d001',
    //     '0xe02D3558765e603bDaAB3b2d38A4714aA8ce9159'
    // ],true,{
    //     gasLimit:12000000
    // });
    // await tx24.wait();



/**
 * 
 0xF3F13Eaf11886a1daf4F8A004488EDD5d35284F8

0xA70882DFb3745Cb175157A7C2DBC7e5b43A5ADb3

0xf4c32d64E2eC1a206bFB8E586B8c4E460154432A

0xd1c6FE47623dD12C041dee9188E0d40A7038C46c

0xC37850699319C1d1664B62975c733e29A5FA13ea

0xa2d46F61Ed621be1Cd4e3b97aD29b4ccB2f032E3

0x155F602BD1aC1037c56A7e79c4592c22C7859344

0xd659ECB542dD3684e3Fb54b05fFbA425ff5CAC6E

0xA4D93994b25cb00E6b74a40357208aF705B2E025
 */

    const tx26 = await tokenContract.batchUpdateTradeWhitelist(['0x083F626DCe22D98671DD86Adb916B59E65f8CE06','0xbA79620A4ed050dd7240Fe206D1896778F86a84C',
        '0xF3F13Eaf11886a1daf4F8A004488EDD5d35284F8',
        '0xA70882DFb3745Cb175157A7C2DBC7e5b43A5ADb3',
        '0xf4c32d64E2eC1a206bFB8E586B8c4E460154432A',
        '0xd1c6FE47623dD12C041dee9188E0d40A7038C46c',
        '0xC37850699319C1d1664B62975c733e29A5FA13ea',
        '0xa2d46F61Ed621be1Cd4e3b97aD29b4ccB2f032E3',
        '0x155F602BD1aC1037c56A7e79c4592c22C7859344',
        '0xd659ECB542dD3684e3Fb54b05fFbA425ff5CAC6E',
        '0xA4D93994b25cb00E6b74a40357208aF705B2E025'
    ],true);
    await tx26.wait();


    const tx25 = await tokenContract.batchSetTradeWhitelistBuyLimit(['0x083F626DCe22D98671DD86Adb916B59E65f8CE06','0xbA79620A4ed050dd7240Fe206D1896778F86a84C',
        '0xF3F13Eaf11886a1daf4F8A004488EDD5d35284F8',
        '0xA70882DFb3745Cb175157A7C2DBC7e5b43A5ADb3',
        '0xf4c32d64E2eC1a206bFB8E586B8c4E460154432A',
        '0xd1c6FE47623dD12C041dee9188E0d40A7038C46c',
        '0xC37850699319C1d1664B62975c733e29A5FA13ea',
        '0xa2d46F61Ed621be1Cd4e3b97aD29b4ccB2f032E3',
        '0x155F602BD1aC1037c56A7e79c4592c22C7859344',
        '0xd659ECB542dD3684e3Fb54b05fFbA425ff5CAC6E',
        '0xA4D93994b25cb00E6b74a40357208aF705B2E025'
    ],[ethers.utils.parseEther('1000000'),ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
        ethers.utils.parseEther('1000000'),
         ethers.utils.parseEther('1000000')

    ]);
    await tx25.wait();

    console.log("213:","0x083F626DCe22D98671DD86Adb916B59E65f8CE06",await tokenContract.getTradeWhitelistBuyLimit("0x083F626DCe22D98671DD86Adb916B59E65f8CE06"));

  
   


}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 
npx hardhat run ./scripts/bridge_standard/mainnet/deployUAG_on_mainnet.ts --network pijs

UAG address is: 0xe6Abc3Efd6818f20143D7587dCac5cb336F93640
UAG/USDT pairAddress is: 0x577B0C2c921b75486ed87Ef33f517eab9102E15e
 */