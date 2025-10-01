import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SpritNFTT1,SpritNFTT3,NFTManage} from  "../../typechain-types";


async function main(){
    const [owner,operator] = await ethers.getSigners();
     const batchTransferFactory = await ethers.getContractFactory("BatchTransferUpgradeable");
    // const batchTransfer = await upgrades.deployProxy(batchTransferFactory,[20000],{ kind:'uups'});
    const batchTransfer = await upgrades.upgradeProxy('0x37E0FFC3fF10094892C4A548fFa4435c2DcA22E1', batchTransferFactory, { kind: 'uups' });
    await batchTransfer.deployed();
    console.log("BatchTransferUpgradeable contract address:",batchTransfer.address);


}


main().catch(error => {
    console.log(error);
    process.exitCode = 1;
});

/**
 npx hardhat run ./scripts/node/deploy_BatchTransferUpgradeable_testnet.ts --network pijstestnet

BatchTransferUpgradeable contract address: 0x37E0FFC3fF10094892C4A548fFa4435c2DcA22E1

// 单币种批量转账 - 不同金额
function batchTransferDifferentAmounts(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotStopped 
event  BatchTransferDifferentAmounts(address token,address caller,address[] recipients,uint256[] amounts,uint256 totalAmount,uint256 recipientsCount,uint256 timestamp);
// 多币种批量转账
function batchTransferMultipleTokens(
        address[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotStopped 
    event  BatchTransferDifferentTokenAmounts(address[] token,address caller,address[] recipients,uint256[] amounts,uint256 recipientsCount,uint256 timestamp);
// 单币种批量转账 - 相同金额
function batchTransferSameAmount(
        address token,
        address[] calldata recipients,
        uint256 amount
    ) external nonReentrant whenNotStopped
event BatchTransferSameAmount(address token, address caller,address[] recipients,uint256 amount,uint256 totalAmount,uint256 recipientsCount,uint256 timestamp);
    


 */