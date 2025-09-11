// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract GenesisNode is ERC721Enumerable, ERC721Holder, AccessControl {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    mapping(address => bool) private whiteList; 
    string public baseUri;

    Counters.Counter private idCounter;

    bool public transferSwitch;
     constructor(address _operator) ERC721("Genesis NFT", "Genesis NFT") {
        idCounter.initial(1);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
    }
    // add to WhiteList
    function setAddressToWhiteList(address _address) external onlyRole(OPERATOR_ROLE) {
        whiteList[_address] = true;
    }

    // remove from blacklist
    function removeFromBlackList(address _address) external  onlyRole(OPERATOR_ROLE) {
        require(isWhiteListed(_address),"Address not in white list");
        whiteList[_address] = false;
    }
    // 检查地址是否在白名单中
    function isWhiteListed(address _address) public view returns (bool) {
        return  whiteList[_address];
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

    function updataTransferSwitch(
        bool _transferSwitch
    ) public onlyRole(MANAGE_ROLE) {
        transferSwitch = _transferSwitch;
    }

    function mint(
        address receiver
    ) external onlyRole(OPERATOR_ROLE) returns (uint256) {
        uint256 currentTokenId = idCounter.current();
        idCounter.increment();
        _safeMint(receiver, currentTokenId);
        return currentTokenId;
    }

    function batchMint(
        address receiver,
        uint amount
    ) external onlyRole(OPERATOR_ROLE) {
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

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        require(transferSwitch || isWhiteListed(msg.sender), "NFT: NOT SUPPORT TRANSFER");
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        require(transferSwitch, "NFT: NOT SUPPORT TRANSFER");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

     /**
     * @dev 批量转移 NFT
     * @param from 出售者/原持有者
     * @param to 接收者
     * @param tokenIds 要转移的 tokenId 数组
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external {
        require(transferSwitch || isWhiteListed(msg.sender), "NFT: NOT SUPPORT TRANSFER");
        require(to != address(0), "NFT: transfer to the zero address");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: caller is not token owner nor approved"
            );

            _transfer(from, to, tokenId);
        }
    }

    function getCurrentCounter() public  view  returns(uint256) {
        return idCounter.current();
    }
   
}
