// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;

    // 存款函数
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // 取款函数（存在重入漏洞）
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // ⚠️ 1. 先发送 ETH
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        // ⚠️ 2. 再修改余额（漏洞所在）
        balances[msg.sender] -= _amount;
    }

    // 查询合约余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
