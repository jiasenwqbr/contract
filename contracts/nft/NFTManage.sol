// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../utils/SafeMath.sol";
interface INFT {
    function mint(address receiver) external returns (uint256);
    function mintTo(address user,string calldata imageData, string calldata name_, string calldata desc_) external returns(uint256);
    function tokenURI(uint256 tokenId) external view  returns (string memory);
    function balanceOf(address owner) external view  returns (uint256);
    function setNFTMeta(address user,uint256 tokenId,string calldata imageData, string calldata name_, string calldata desc_) external ;
}
contract NFTManage is 
    Initializable,
    ERC721Holder, 
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
        using SafeMath for uint;

        bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
        address public nftT1Address;
        address public nftT3Address;

        function initialize(address _nftT1Address,address _nftT3Address) public initializer {
            __AccessControlEnumerable_init();
            __ReentrancyGuard_init();
            __UUPSUpgradeable_init();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(MANAGE_ROLE, msg.sender);
            nftT1Address = _nftT1Address;
            nftT3Address = _nftT3Address;
        }

        /// @custom:oz-upgrades-unsafe-allow constructor
        constructor() {
            _disableInitializers();
        }
        event MintNFT(address caller,address nftContractAddress,uint256 communityId,uint256 tokenid,string imageData,uint256 timestamp);

        function _authorizeUpgrade(
            address newImplementation
        ) internal override onlyRole(MANAGE_ROLE) {}

        function mintNFT(uint256 communityId,string calldata imageData, string calldata name_, string calldata desc_) public {
            require(INFT(nftT1Address).balanceOf(msg.sender) == 0  && INFT(nftT3Address).balanceOf(msg.sender) == 0,"NFTManage:only have 1 nft in T1 or T3");
            if (communityId == 1){
                uint256 tokenid = INFT(nftT1Address).mintTo(msg.sender,imageData,name_,desc_);
                emit MintNFT(msg.sender,nftT1Address,communityId,tokenid,imageData,block.timestamp);
            } else if (communityId == 3){
                uint256 tokenid =  INFT(nftT3Address).mintTo(msg.sender,imageData,name_,desc_);
                emit MintNFT(msg.sender,nftT3Address,communityId,tokenid,imageData,block.timestamp);
            } else {
                require(false,"NFTManage:Invalid param");
            }

        }

        function changeNFIImage(uint256 communityId,uint256 tokenId,string calldata imageData, string calldata name_, string calldata desc_) public {
            if (communityId == 1){
                INFT(nftT1Address).setNFTMeta(msg.sender,tokenId,imageData,name_,desc_);
            } else if (communityId == 3){
                INFT(nftT3Address).setNFTMeta(msg.sender,tokenId,imageData,name_,desc_);
            } else {
                require(false,"NFTManage:Invalid param");
            }
        }
    }   