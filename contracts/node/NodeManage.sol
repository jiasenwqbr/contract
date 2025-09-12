// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/SafeMath.sol";
import "./GenesisNode.sol";

contract NodeManage is 
    Initializable,
    ERC721Holder, 
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {
    using SafeMath for uint;
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");
    bytes32 public DOMAIN_SEPARATOR;
    // 签名者
    address public signer;
    address[3] feeReceiver;
    uint256[3] feeReceiverRatio;
    mapping(address => uint) public nonces;
    mapping(address => mapping(address => uint256[])) public userNodes;
    mapping(address => mapping(address => uint256[])) userProductOrderIds;

     // 订单
    struct Order {
        address buyer;
        uint256 orderId;
        address tokenAddress;
        uint256 tokenAmount;
        address nodeAddress;
        uint256 buyAmount;
        address recommender;
        uint256 collectRatio;
        uint256 timestamp;
    }
    // 产品
    struct Product {
        uint256 productId;
        address productAddress;
        bool enabled;
    }
    mapping(address => mapping(uint256 => Order)) userOrder;
    address public usdt;
    mapping(address => Product) productInfo;
    bytes32 private constant PERMIT_BUYNODE_TYPEHASH = keccak256(
        abi.encodePacked("Permit(address buyer,uint256 orderId,address tokenAddress,uint256 tokenAmount,address nodeAddress,uint256 buyAmount,address recommender,uint256 collectRatio)")
    );

    function initialize( 
        address _signer,
        address[3] memory _feeReceiver,
        uint256[3] memory _feeReceiverRatio,
        address _usdt) public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGE_ROLE, msg.sender);

        signer = _signer;
        feeReceiver = _feeReceiver;
        feeReceiverRatio = _feeReceiverRatio;
        usdt = _usdt;
        uint256 chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("NodeManage")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁止逻辑合约自己初始化
    }
    
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MANAGE_ROLE) {}
    
    event BuyNode(address caller,uint256 productId,uint256 orderId,address tokenAddress,uint256 tokenAmount,address nodeAddress,uint256 buyAmount,uint256 nodeId,address feeReceiver1,uint256 fee1,address feeReceiver2,uint256 fee2,address feeReceiver3,uint256 fee3,address recommender,uint256 recomanderFee,uint256 timestamp);
    

    function buyNode(bytes calldata data) public nonReentrant {
        // 1.参数解析与校验
        Order memory order =  parseOrderData(data);
        // 购买者校验
        require(order.buyer == msg.sender,"NodeManage:buyer error");
        require(order.recommender != address(0),"NodeManage:recommender error");
        // 币种校验
        require(order.tokenAddress == usdt,"NodeManage:buyer token error");
        // 购买数量校验
        require(order.buyAmount == 1,"NodeManage:buyAmount must be 1");
        // Amount校验
        require(IERC20(usdt).allowance(msg.sender, address(this)) >= order.tokenAmount,"NodeManage:allowance");
        // 订单校验
        require(userOrder[msg.sender][order.orderId].orderId == 0,"NodeManage:order exist");
        // 验证购买产品
        require(productInfo[order.nodeAddress].enabled == true,"NodeManage:The node is not enabled");
        require(userProductOrderIds[msg.sender][order.nodeAddress].length<=1,"NodeManage:Maximum number of purchases");
        // 2.收取费用与mint
        IERC20 paymentToken = IERC20(order.tokenAddress);
        uint256 recomanderFee = order.tokenAmount.mul(order.collectRatio).div(1000);
        uint256 fee1 = order.tokenAmount.mul(feeReceiverRatio[0]).div(1000);
        uint256 fee2 = order.tokenAmount.mul(feeReceiverRatio[1]).div(1000);
        uint256 fee3 = order.tokenAmount.sub(recomanderFee).sub(fee1).sub(fee2);

        require(
            paymentToken.transferFrom(msg.sender, order.recommender, recomanderFee ),
            "NodeManage:Payment transfer failed"
        );

        require(
            paymentToken.transferFrom(msg.sender, feeReceiver[0], fee1),
            "NodeManage:Payment transfer failed"
        );
        require(
            paymentToken.transferFrom(msg.sender, feeReceiver[1], fee2),
            "NodeManage:Payment transfer failed"
        );
        require(
            paymentToken.transferFrom(msg.sender, feeReceiver[2], fee3 ),
            "NodeManage:Payment transfer failed"
        );
        
        uint256 nodeId;
        if (productInfo[order.nodeAddress].productId == 1){
            nodeId = GenesisNode(order.nodeAddress).mint(msg.sender);
        }
        // 3.写入订单
        userOrder[msg.sender][order.orderId] = order;
        userNodes[msg.sender][order.nodeAddress].push(nodeId);
        userProductOrderIds[msg.sender][order.nodeAddress].push(order.orderId);
        // 4.广播事件
        emit BuyNode(msg.sender,productInfo[order.nodeAddress].productId,order.orderId,order.tokenAddress,order.tokenAmount,order.nodeAddress,order.buyAmount,nodeId,feeReceiver[0],fee1,feeReceiver[1],fee2,feeReceiver[2],fee3,order.recommender,recomanderFee,order.timestamp);
    }

    function parseOrderData(bytes calldata data) internal view returns (Order memory) {
        /**
         * @param buyer 购买者地址
         * @param orderId 订单Id
         * @param tokenAddress usdt地址
         * @param tokenAmount 支付usdt数量
         * @param nodeAddress 节点地址
         * @param buyAmount 购买数量
         * @param signature 签名
         */
        (
            address buyer,
            uint256 orderId,
            address tokenAddress,
            uint256 tokenAmount,
            address nodeAddress,
            uint256 buyAmount,
            address recommender,
            uint256 collectRatio,
            bytes memory signature
        ) = abi.decode(
            data,
            (
                address,
                uint256,
                address,
                uint256,
                address,
                uint256,
                address,
                uint256,
                bytes
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_BUYNODE_TYPEHASH,
                        buyer,
                        orderId,
                        tokenAddress,
                        tokenAmount,
                        nodeAddress,
                        buyAmount,
                        recommender,
                        collectRatio
                    )
                )
            )
        );
        require(
            signer == ecrecover(signHash, v, r, s),
            "NFTSellManage: INVALID_REQUEST"
        );

        return Order({
            buyer:buyer,
            orderId:orderId,
            tokenAddress:tokenAddress,
            tokenAmount:tokenAmount,
            nodeAddress:nodeAddress,
            buyAmount:buyAmount,
            recommender:recommender,
            collectRatio:collectRatio,
            timestamp:block.timestamp
        });
    }


    function splitSignature(
            bytes memory sig
        ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "CrossBackContract:Not Invalid Signature Data");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly  ("memory-safe") {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    //////////////////////////////////  Seter
    // feeReceiver
    function setFeeReceiver(address[3] memory _feeReceiver) public onlyRole(MANAGE_ROLE){
        feeReceiver = _feeReceiver;
    }
    function getFeeReceiver() public view returns(address[3] memory) {
        return feeReceiver;
    }
    // productInfo
    function addProduct(uint256 productId,address productAddress,bool enabled)  public onlyRole(MANAGE_ROLE){
        productInfo[productAddress] = Product({
            productId:productId,
            productAddress:productAddress,
            enabled:enabled
        });
    }

    function getProduct(address productAddress) public view returns(Product memory){
        return productInfo[productAddress];
    }
    function setProductStatus(address productAddress,bool enabled) public onlyRole(MANAGE_ROLE) {
        productInfo[productAddress].enabled = enabled;
    }

    // userNodes
    function getUserNodes(address userAddress,address nodeAddress) public view returns(uint256[] memory){
        return userNodes[userAddress][nodeAddress];
    }
    function getUserOrders(address userAddress,address productAddress) public view returns(Order[] memory) {
        uint256[] memory orderids= userProductOrderIds[userAddress][productAddress];
        Order[] memory orders = new Order[](orderids.length);
        for (uint256 i = 0;i<orderids.length;i++){
            orders[i]=userOrder[userAddress][orderids[i]];
        }
        return orders;
    }
}