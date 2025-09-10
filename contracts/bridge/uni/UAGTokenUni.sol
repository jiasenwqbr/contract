// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UAG is ERC20, Ownable {
    constructor(address receiver,uint256 _totalSupply) ERC20("UAG", "UAG") {
        _mint(receiver, _totalSupply);
    }
}