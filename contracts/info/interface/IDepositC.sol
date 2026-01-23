// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IDepositC {
    function reduceSalseQuota(address user,uint256 infoAmount) external;
    function addSalseQuota(address user,uint256 infoAmount) external ;
    function addSalseQuotaUSDT(address user,uint256 usdtAmount) external ;
}