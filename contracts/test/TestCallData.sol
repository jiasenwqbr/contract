
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TestCallData {

    function test(uint256[] memory  arr) public pure {
        arr[0] = 100;
    }

}