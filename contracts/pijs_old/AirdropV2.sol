// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Airdrop.sol";
contract AirdropV2 is Airdrop {
    function version() public pure returns (string memory) {
        return "V2";
    }
}