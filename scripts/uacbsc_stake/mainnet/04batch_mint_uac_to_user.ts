import { ethers } from "hardhat";
import { UACBSC } from  "../../../typechain-types";
import fs from "fs";
import csv from "csv-parser";
import { BigNumber } from "ethers";
interface Row {
    id: string;
    addr: string;
    pow_earn:Number;
    referee_pos_earn:Number;
    pos_earn:Number;
    additional:number;
    earn_num:number;
    balance_eth:Number;
    stake_num:Number;
    total:Number;
}   


async function main() {

    const uac_address = "0x62f59D17B395B4437Cc4C673d075b898D2d95eAe";
    const uac = await ethers.getContractAt("UACBSC",uac_address) as UACBSC;
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const rows = await readCSV("/Users/jason/Desktop/code/web3/bridge/scripts/uacbsc_stake/mainnet/intergrate.csv");
    

    console.log("------------------------------------------------------------------------",rows.length);
    let totalSum = ethers.constants.Zero;
    //for (let i = 0; i< rows.length;i++){
     for (let i = 79; i< 80;i++){
        console.log(
                    i,rows[i].id,rows[i].addr, rows[i].total
        );
        if (rows[i].total.valueOf()>0){
            const beforeBalance = await uac.balanceOf(rows[i].addr);
            console.log("before mint balance:",rows[i].addr,ethers.utils.formatEther(beforeBalance));
            if (beforeBalance.gt(0)){
                console.log(rows[i].addr,"is minted");
            }else {
                // begin mint
                // const tx = await uac.connect(owner).mint(rows[i].addr,ethers.utils.parseEther(rows[i].total.toLocaleString()));
                const tx = await uac.connect(owner).transfer(rows[i].addr,ethers.utils.parseEther(rows[i].total.toLocaleString()));
                await tx.wait();
                // await sleep(500); // sleep for 2 seconds
                console.log("after mint balance:",rows[i].addr,ethers.utils.formatEther(await uac.balanceOf(rows[i].addr)));

            }
            

            totalSum = totalSum.add(
                ethers.utils.parseEther(rows[i].total.toString())
            );


        } else {
             console.log(rows[i].addr,"is 0");
        }
        // await sleep(500); // sleep for 2 seconds

         
        


    }
    console.log("------------------------------------------------------------------------totalSum：", ethers.utils.formatEther(totalSum));







}

main();


function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function readCSV(path: string): Promise<Row[]> {
    return new Promise((resolve, reject) => {
        const results: Row[] = [];
        fs.createReadStream(path)
            .pipe(csv())
            .on("data", (data: Row) => {
                results.push(data);
            })
            .on("end", () => {
                resolve(results);
            })
            .on("error", reject);
    });
}


/**
 * 
 npx hardhat run ./scripts/uacbsc_stake/mainnet/04batch_mint_uac_to_user.ts --network ganache
 npx hardhat run ./scripts/uacbsc_stake/mainnet/04batch_mint_uac_to_user.ts --network bscmainnet
 
 * 
 */