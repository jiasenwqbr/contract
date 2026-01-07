// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
contract AsiaTelevisionINFONFT is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    string public baseUri;

    Counters.Counter private idCounter;

    bool public transferSwitch;

    constructor() ERC721("INFO", "Asia Television INFO") {
        idCounter.initial(1);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        transferSwitch = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function updateBaseUri(
        string memory _baseUri
    ) public onlyRole(MANAGE_ROLE) {
        require(bytes(_baseUri).length > 0, "ERROR:ZERO_LENGTH");
        baseUri = _baseUri;
    }

    function updateTransferSwitch(
        bool _transferSwitch
    ) public onlyRole(MANAGE_ROLE) {
        transferSwitch = _transferSwitch;
    }

    function mint(
        address receiver
    ) external onlyRole(MANAGE_ROLE) returns (uint256) {
        uint256 currentTokenId = idCounter.current();
        idCounter.increment();
        _safeMint(receiver, currentTokenId);
        return currentTokenId;
    }

    function batchMint(
        address receiver,
        uint amount
    ) external onlyRole(MANAGE_ROLE) {
        for (uint i = 0; i < amount; i++) {
            uint256 currentTokenId = idCounter.current();
            idCounter.increment();
            _safeMint(receiver, currentTokenId);
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


}
