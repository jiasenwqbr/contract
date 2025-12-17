// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BlockRewardController {
    event RewardSetUpdated(
        address indexed signer,
        address[] receivers,
        uint256[] weights
    );

    address public governance;

    constructor(address _gov) {
        governance = _gov;
    }

    modifier onlyGov() {
        require(msg.sender == governance, "not gov");
        _;
    }

    function updateRewardSet(
        address signer,
        address[] calldata receivers,
        uint256[] calldata weights
    ) external onlyGov {
        require(receivers.length == weights.length, "len mismatch");
        emit RewardSetUpdated(signer, receivers, weights);
    }
}
