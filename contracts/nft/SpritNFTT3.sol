// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @dev Encodes `data` to base64 string
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, mload(data)) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                out := shl(8, out)
                out := add(out, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                out := shl(8, out)
                out := add(out, mload(add(tablePtr, and(input, 0x3F))))

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) // "=="
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d)) // "="
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
struct NFTData {
    string name;
    string image;
    string description;

}
contract SpritNFTT3 is ERC721Enumerable, ERC721Holder, AccessControl ,Ownable{
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using Base64 for bytes;

    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    mapping(address => bool) private whiteList; 
    string public baseUri;

    Counters.Counter private idCounter;
    uint256 public circulation;

    bool public transferSwitch;

    // store raw image bytes (e.g. PNG) per token
    mapping(uint256 => string) private _imageBytes;
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => string) private _tokenDescription;
    // limit to avoid accidental insane gas usage (default 50 KB)
    uint256 public maxImageBytes = 1024 * 1024;

    event Minted(address indexed owner, uint256 indexed tokenId, uint256 imageSize);

    constructor(address _operator) ERC721("Sprit NFT T3", "Sprit NFT T3") {
        idCounter.initial(1);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
    }

     // add to whitelist
    function setAddressToWhiteList(address _address) external onlyRole(OPERATOR_ROLE) {
        whiteList[_address] = true;
    }

    // remove from whitelist
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

    function mintTo(address user,string calldata imageData, string calldata name_, string calldata desc_) external onlyRole(OPERATOR_ROLE) payable returns(uint256){
        require(bytes(imageData).length > 0, "string is empty");
        uint256 tokenId = idCounter.current();
        _safeMint(user, tokenId);

        // store image and metadata
        _imageBytes[tokenId] = imageData; // copies calldata to storage (expensive)
        _tokenName[tokenId] = name_;
        _tokenDescription[tokenId] = desc_;
        idCounter.increment();
        emit Minted(user, tokenId, bytes(imageData).length);

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Nonexistent");

        string memory image = _imageBytes[tokenId];

        // You can change MIME type if storing SVG or JPEG: image/svg+xml or image/jpeg
        string memory imageDataURI = string(abi.encodePacked("data:image/png;base64,", image));

        string memory name_ = _tokenName[tokenId];
        string memory desc_ = _tokenDescription[tokenId];

        bytes memory json = abi.encodePacked(
            '{"name":"', name_, '",',
            '"description":"', desc_, '",',
            '"image":"', imageDataURI, '"}'
        );

        string memory jsonBase64 = Base64.encode(json);
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }

    /// @notice owner can change size limit
    function setMaxImageBytes(uint256 newMax) external onlyOwner {
        maxImageBytes = newMax;
    }

    /// @notice return the on-chain image raw bytes (if needed)
    function imageBytesOf(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Nonexistent");
        return _imageBytes[tokenId];
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



    function getNFTByTokenId(uint256 tokenId) public view  returns (NFTData memory) {
        require(_exists(tokenId), "Nonexistent");
        return NFTData({
            name:_tokenName[tokenId],
            image: _imageBytes[tokenId],
            description: _tokenDescription[tokenId]
        });
    }

    function getUserNFTs(address user) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }

        return tokenIds;
    }

    function setNFTMeta(address user,uint256 tokenId,string calldata imageData, string calldata name_, string calldata desc_) external onlyRole(OPERATOR_ROLE) {
        uint256 balance = balanceOf(user);
        bool hasToken = false;
        for (uint256 i = 0; i < balance; i++) {
            if (tokenOfOwnerByIndex(user, i) == tokenId){
                hasToken = true;
                break;
            }
        }
        require(hasToken,"the token is not belong to the user");
         _imageBytes[tokenId] = imageData; 
        _tokenName[tokenId] = name_;
        _tokenDescription[tokenId] = desc_;
    }
}