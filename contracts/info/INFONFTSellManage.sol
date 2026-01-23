// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./RecommendationINFO.sol";
interface INFT {
    function mint(address receiver) external returns (uint256);
}

contract INFONFTSellManage is  Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
        bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
        /// @custom:oz-upgrades-unsafe-allow constructor
        constructor() {
            _disableInitializers();
        }

        function _authorizeUpgrade(
            address newImplementation
        ) internal override onlyRole(MANAGE_ROLE) {}

        function initialize(
            address _usdtAddress,
            address _nftAddress,
            address _receiver,
            address _rootRecommender,
            address _recommandContractAddress
        ) public initializer {
            __AccessControlEnumerable_init();
            __ReentrancyGuard_init();
            __UUPSUpgradeable_init();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(MANAGE_ROLE, msg.sender);

            usdtAddress = _usdtAddress;
            nftAddress = _nftAddress;
            receiver = _receiver;
            rootRecommender = _rootRecommender;
            recommandContractAddress = _recommandContractAddress;
        }

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    /////////////////////////////////////////////////////////////*/
    address usdtAddress;
    address nftAddress;
    address receiver;
    address rootRecommender;
    address recommandContractAddress;
    mapping(address => uint256) userNfts;
    uint256 public price;
    uint256 public currentNftId;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event BuyNode(address user,address recommender,address usdtAddress,uint256 amount,address receiver,address nftAddress,uint256 niftId,uint256 createTime);
    event MintNFT(address manager,address to,uint256 nftId,uint256 createTime);
    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function buyNode(address usdtTokenAddress,uint256 amount,address recommender) public payable nonReentrant {
        require(usdtTokenAddress!=address(0),"0 address");
        
        //require(recommender!=address(0),"0 address");
        require(usdtTokenAddress == usdtAddress,"invalid usdt address");
        require(amount >= price);
        RecommendationINFO recommand = RecommendationINFO(recommandContractAddress);
        (address referAddress,,,) = recommand.getUserInfo(msg.sender);
        // if (recommender!=rootRecommender){
        //     (address referAddress,,,) = recommand.getUserInfo(msg.sender);
        //     require(referAddress!= address(0),"need recommander");
        //     require(referAddress == recommender,"need recommander");
        // }
        require(referAddress!= address(0),"need recommander");
        require(receiver!= address(0),"0 address");
        require(userNfts[msg.sender] == 0,"1 nft limit");

        // tranfer
        require(
            IERC20(usdtAddress).transferFrom(msg.sender, receiver, amount),
            "transferFrom failed"
        );
        // mint nft
        uint256 niftId = INFT(nftAddress).mint(msg.sender);
        // update recommand relationship
        // recommand.updateRecommandShip(recommender,msg.sender);

        // update userNfts
        userNfts[msg.sender] = niftId;
        currentNftId = niftId;

        emit BuyNode(msg.sender,referAddress,usdtAddress,amount,receiver,nftAddress,niftId,block.timestamp);
    }

    function getUserNFT(address user) public view returns(uint256) {
        return userNfts[user];
    }

    function setPrice(uint256 _price) public onlyRole(MANAGE_ROLE) {
        price = _price;
    }

    function mintNFT(address to) public nonReentrant onlyRole(MANAGE_ROLE) {
        uint256 nftId = INFT(nftAddress).mint(to);
        currentNftId = nftId;
        userNfts[to] = nftId;
        emit MintNFT(msg.sender,to,nftId,block.timestamp);
    }

    function setParam(
        address _usdtAddress,
        address _nftAddress,
        address _receiver,
        address _rootRecommender,
        address _recommandContractAddress
    ) public onlyRole(MANAGE_ROLE) {
        require(_usdtAddress != address(0),"0 address");
        require(_nftAddress != address(0),"0 address");
        require(_receiver != address(0),"0 address");
        require(_rootRecommender != address(0),"0 address");
        require(_recommandContractAddress != address(0),"0 address");
        usdtAddress = _usdtAddress;
        nftAddress = _nftAddress;
        receiver = _receiver;
        rootRecommender = _rootRecommender;
        recommandContractAddress = _recommandContractAddress;
    }


}