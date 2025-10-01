// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
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

        uint256  constant  DENOMINATOR = 1000;
        uint256 private devideMolecular; 
        address usdtAddress;
        address feeReceiver;
        address swapRouterAddress;

        uint256 tokenAmountLimit;

        

       

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
        event MintNFTWithToken(address caller,address nftContractAddress,uint256 communityId,uint256 tokenid,string imageData,address tokenAddress,uint256 tokenAmount,uint256 buyPijsAmount,address feeReceiver,uint256 fee,uint256 timestamp);

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

        function mintNFTWithToken(uint256 communityId,address tokenAddress,uint256 tokenAmount,string calldata imageData, string calldata name_, string calldata desc_) public {
            require(INFT(nftT1Address).balanceOf(msg.sender) == 0  && INFT(nftT3Address).balanceOf(msg.sender) == 0,"NFTManage:only have 1 nft in T1 or T3");
            require(tokenAddress == usdtAddress,"NFTManage:Invalid token address");
            require(tokenAmount != 0,"NFTManage:Invalid tokenAmount");
            require(tokenAmount >= tokenAmountLimit,"NFTManage:tokenAmount must gt or eq tokenAmountLimit");
            uint256 buyPijsAmount = tokenAmount.mul(devideMolecular).div(DENOMINATOR);
            uint256 fee = tokenAmount.sub(buyPijsAmount);

            if (communityId == 1){
                require(
                    IERC20(tokenAddress).transferFrom(msg.sender, feeReceiver, fee),
                    "NFTManage:Payment transfer failed"
                );
                // swap pijs
                buyPIJS(tokenAddress,buyPijsAmount,0,msg.sender);
                // mint nft
                uint256 tokenid = INFT(nftT1Address).mintTo(msg.sender,imageData,name_,desc_);
                emit MintNFTWithToken(msg.sender,nftT1Address,communityId,tokenid,imageData,tokenAddress,tokenAmount,buyPijsAmount,feeReceiver,fee,block.timestamp);
            }  else if (communityId == 3){
                require(
                    IERC20(tokenAddress).transferFrom(msg.sender, feeReceiver, fee),
                    "NFTManage:Payment transfer failed"
                );
                // swap pijs
                buyPIJS(tokenAddress,buyPijsAmount,0,msg.sender);
                // mint nft
                uint256 tokenid = INFT(nftT3Address).mintTo(msg.sender,imageData,name_,desc_);
                emit MintNFTWithToken(msg.sender,nftT3Address,communityId,tokenid,imageData,tokenAddress,tokenAmount,buyPijsAmount,feeReceiver,fee,block.timestamp);
            } else {
                require(false,"NFTManage:Invalid param");
            }

        }
        function buyPIJS(address tokenAddress,uint256 amountIn,uint256 amountOutMin,address to) internal {
                IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouterAddress);
                // 1. 将用户的 USDT 转到本合约
                IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountIn);
                // 2. 授权给 Router
                IERC20(tokenAddress).approve(address(swapRouter), 0);
                IERC20(tokenAddress).approve(address(swapRouter), amountIn);
                // 3. 设置兑换路径 USDT -> 目标代币

                address[] memory path = new address[](2);
                path[0] = tokenAddress;
                path[1] = IUniswapV2Router02(address(swapRouter)).WETH();
                // 4. 调用 swapExactTokensForTokens
                swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOutMin, // 最小预期输出，防止滑点
                    path,
                    to, // 接收代币的地址
                    block.timestamp + 300 // 5分钟有效期
                );
        }
        ///////////  setter
        function setDevideMolecular(uint256 _devideMolecular) public onlyRole(MANAGE_ROLE) {
            require(_devideMolecular < DENOMINATOR,"NFTManage:Invalid devide");
            devideMolecular = _devideMolecular;
        }

        function gettDevideMolecular() public view returns(uint256){
            return devideMolecular;
        }

        function setFeeReceiver(address _feeReceiver) public onlyRole(MANAGE_ROLE) {
            feeReceiver = _feeReceiver;
        }
        function getFeeReceiver() public view returns(address) {
            return feeReceiver;
        }

        function setUsdtAddress(address _usdtAddress) public onlyRole(MANAGE_ROLE) {
            usdtAddress = _usdtAddress;
        }
        function getUsdtAddress() public view returns(address){
            return usdtAddress;
        }
        function setSwapRouterAddress(address _swapRouterAddress) public onlyRole(MANAGE_ROLE) {
            swapRouterAddress = _swapRouterAddress;
        }
        function getSwapRouterAddress() public view returns(address) {
            return swapRouterAddress;
        }
        function setTokenAmountLimit(uint256 _tokenAmountLimit) public onlyRole(MANAGE_ROLE){
            tokenAmountLimit = _tokenAmountLimit;
        }
        function getTokenAmountLimit() public view returns(uint256){
            return tokenAmountLimit;
        }


       


    }   