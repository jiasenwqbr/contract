import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {UAGERC20} from  "../../../typechain-types";
import { Contract } from "ethers";
import * as XLSX from "xlsx";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    const tokenContract = await ethers.getContractAt("UAGERC20","0xe6Abc3Efd6818f20143D7587dCac5cb336F93640") as UAGERC20;
    const pages = readExcelInPages("/Users/jason/Desktop/code/web3/bridge/scripts/bridge_standard/mainnet/UAG_receiver.xls",500);
    console.log("1:","0x4bcba33f01D74E63E2385148B853Fb57E8573db4",await tokenContract.getTradeWhitelistBuyLimit("0x4bcba33f01D74E63E2385148B853Fb57E8573db4"));
    console.log("213:","0x619a1B6704Faf584a9DD6ed602237B4fd2ac32fb",await tokenContract.getTradeWhitelistBuyLimit("0x619a1B6704Faf584a9DD6ed602237B4fd2ac32fb"));
    for (const [index, page] of pages.entries()) {
        console.log(`处理第 ${index + 1} 页，共 ${page.length} 行`);
        // console.log(page);
        
        let witeList = [];
        let limits = [];
        
        for (let i = 0; i < page.length; i++) {
            witeList.push(page[i].wallet_address);
            limits.push(ethers.utils.parseEther(page[i].limit.toString()));
        }
        
        try {
            const tx5 = await tokenContract.batchUpdateTradeWhitelist(witeList,true);
            await tx5.wait();
            
            const tx4 = await tokenContract.batchSetTradeWhitelistBuyLimit(witeList, limits, {
                gasLimit: 12000000
            });
            console.log(`第 ${index + 1} 页交易已发送: ${tx4.hash}`);

            
            
            // 等待交易确认
            const receipt = await tx4.wait();
            console.log(`第 ${index + 1} 页交易已确认, 状态: ${receipt.status === 1 ? '成功' : '失败'}`);

            
            
        } catch (error) {
            console.error(`第 ${index + 1} 页处理失败:`, error);
            // 可以选择继续处理下一页或终止
            break; // 或者 continue 继续下一页
        }
    }

    console.log("1:","0x4bcba33f01D74E63E2385148B853Fb57E8573db4",await tokenContract.getTradeWhitelistBuyLimit("0x4bcba33f01D74E63E2385148B853Fb57E8573db4"));
    console.log("213:","0x619a1B6704Faf584a9DD6ed602237B4fd2ac32fb",await tokenContract.getTradeWhitelistBuyLimit("0x619a1B6704Faf584a9DD6ed602237B4fd2ac32fb"));



}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// 分页读取 Excel
function readExcelInPages(filePath: string, pageSize: number) {
  // 读取 Excel 文件
  const workbook = XLSX.readFile(filePath);

  // 获取第一个工作表
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];

  // 转成 JSON 数组（每一行是一个对象）
  const rows: any[] = XLSX.utils.sheet_to_json(sheet, { defval: "" });

  // 分页
  const pages: any[][] = [];
  for (let i = 0; i < rows.length; i += pageSize) {
    const page = rows.slice(i, i + pageSize);
    pages.push(page);
  }

  return pages;
}


/***
 * 
 
npx hardhat run ./scripts/bridge_standard/mainnet/updateUagTradeWhiteList_mainnet.ts --network pijs



 */