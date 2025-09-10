// scripts/create-accounts.ts
import { ethers } from "hardhat";
import { Wallet } from "ethers";

interface AccountInfo {
  index: number;
  address: string;
  privateKey: string;
  mnemonic?: string;
}

async function main(): Promise<AccountInfo[]> {
  console.log("🔄 Creating 100 Ethereum wallets...\n");

  const wallets: AccountInfo[] = [];
  
  // 创建100个新钱包
  for (let i = 0; i < 500; i++) {
    const wallet: Wallet = ethers.Wallet.createRandom();
    
    wallets.push({
      index: i + 1,
      address: wallet.address,
      privateKey: wallet.privateKey,
      mnemonic: wallet.mnemonic?.phrase
    });
  }
  
  // 输出所有钱包信息
  console.log("✅ Created 100 wallets:\n");
  wallets.forEach((wallet) => {
    console.log(`#${wallet.index.toString().padStart(3, ' ')}`);
    console.log(`   Address:    ${wallet.address}`);
    console.log(`   Private Key: ${wallet.privateKey}`);
    if (wallet.mnemonic) {
      console.log(`   Mnemonic:    ${wallet.mnemonic}`);
    }
    console.log("─".repeat(60));
  });
  
  // 保存到文件（可选）
  await saveAccountsToFile(wallets);
  
  return wallets;
}

/**
 * 将账户信息保存到JSON文件
 */
async function saveAccountsToFile(accounts: AccountInfo[]): Promise<void> {
  const fs = require("fs").promises;
  const path = require("path");
  
  const outputDir = path.join(__dirname, "../output");
  const filePath = path.join(outputDir, "accounts.json");
  
  try {
    // 确保输出目录存在
    await fs.mkdir(outputDir, { recursive: true });
    
    // 保存账户信息
    await fs.writeFile(
      filePath, 
      JSON.stringify(accounts, null, 2),
      "utf8"
    );
    
    console.log(`\n💾 Account data saved to: ${filePath}`);
    
    // 同时保存一个简化的版本（只有地址和私钥）
    const simplifiedAccounts = accounts.map(acc => ({
      index: acc.index,
      address: acc.address,
      privateKey: acc.privateKey
    }));
    
    await fs.writeFile(
      path.join(outputDir, "accounts-simple.json"),
      JSON.stringify(simplifiedAccounts, null, 2),
      "utf8"
    );
    
  } catch (error) {
    console.warn("⚠️  Could not save accounts to file:", error);
  }
}

/**
 * 验证以太坊地址的有效性
 */
function isValidEthereumAddress(address: string): boolean {
  return ethers.utils.isAddress(address);
}

/**
 * 从私钥创建钱包实例
 */
function createWalletFromPrivateKey(privateKey: string): Wallet {
  return new ethers.Wallet(privateKey);
}

// 运行脚本
main()
  .then(() => {
    console.log("\n🎉 Script completed successfully!");
    process.exit(0);
  })
  .catch((error: Error) => {
    console.error("\n❌ Script failed:", error);
    process.exitCode = 1;
  });