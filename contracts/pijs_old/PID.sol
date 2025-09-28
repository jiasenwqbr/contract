// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PID is ERC20, Ownable {
    constructor(address receiver) ERC20("PID", "PID") {
        _mint(receiver, 200_000_000_000_000_000 * 10 ** decimals());
    }
}
