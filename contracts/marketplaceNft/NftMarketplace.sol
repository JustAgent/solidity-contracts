// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    

    Order[]  ordersTest; // test returns all orders
    uint totalOrders;
    uint256 platformFee = 5; // 5%
    address feeRecipient;
    mapping(uint => Order) public orders; 
    mapping(address => mapping(uint256 => uint)) public ordersId;
    mapping(uint => bool) public activeOrders;


    struct Order {
        address nftContract;
        address maker;
        address taker;
        uint256 tokenId;
        SaleKindInterface.Side side;
        SaleKindInterface.SaleKind saleKind;
        uint basePrice;
        address paymentToken;
        address target;
        uint extra;
        uint listingTime;
        uint expirationTime;
    }


    event SellOrderCreated (
        uint id, 
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed maker,
        SaleKindInterface.SaleKind  saleKind,
        uint basePrice,
        address  paymentToken,
        address target,
        uint extra,
        uint listingTime,
        uint expirationTime
    );

    event BuyExecuted (
        address indexed nftContract,
        uint256 indexed tokenId,
        address buyer
    );

    event NewOffer (
        uint indexed id,
        address nftContract,
        uint256 tokenId, 
        address indexed maker,
        address paymentToken, 
        uint256 basePrice,
        uint listingTime,
        uint expirationTime
    );

    event OfferApplied (
        uint indexed id,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    event OrderCanceled (
        uint indexed id
    );

    event OfferCanceled (
        uint indexed id
    );

    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
    }

    function getTotalOrders() public view returns(uint) {
        return totalOrders;
    }

    
    function transferNFTs(
        address _to, 
        uint256[] memory tokenIds, 
        address nftContract)
        public 
        returns(bool) 
    {
        require(checkApprovalERC721(msg.sender, nftContract), "No allowance");

        IERC721 nft = IERC721(nftContract);
        uint256 length = tokenIds.length;
        for (uint i = 0; i < length; i++) {
             _transferNFT(msg.sender, _to, tokenIds[i], nft);
        }
        return true;
    }

    function _transferNFT(address from, address _to, uint256 tokenId, IERC721 nft) private {
        nft.safeTransferFrom(from, _to, tokenId);
    }

    function checkApprovalERC721(address _user, address nftContract) private view returns(bool) {
        IERC721 nft = IERC721(nftContract);
        return nft.isApprovedForAll(_user, address(this));
    }

    function checkApprovalERC20(address _user, address _tokenAddress) private view returns(uint256) {
        IERC20 token = IERC20(_tokenAddress);
        return token.allowance(_user, address(this));
    }

    function createOrder(
        address nftContract,
        address maker,
        address taker, // Buy
        uint256 tokenId,
        SaleKindInterface.Side side, // Sell or Buy
        SaleKindInterface.SaleKind saleKind, // 
        uint basePrice, // 
        address paymentToken, 
        address target, // Private selling if specified
        uint extra, // 0 if Buy
        uint listingTime,
        uint expirationTime
    )   private 
        pure
        returns(Order memory)
    {
        Order memory order = Order(
            nftContract,
            maker,
            taker,
            tokenId,
            side,
            saleKind,
            basePrice,
            paymentToken,
            target,
            extra,
            listingTime,
            expirationTime
        );
        
        require(validateOrderParameters(order), "Invalid order parameters");
        return order;
    }

    function sell(
        address nftContract,
        uint256 tokenId,
        uint8 _saleKind, 
        uint basePrice, 
        address paymentToken,
        address target, 
        uint extra, 
        uint256 listingTime) 
        public
        nonReentrant
    {
        require(checkApprovalERC721(msg.sender, nftContract), "No allowance");
        SaleKindInterface.Side side = SaleKindInterface.Side.Sell;
        SaleKindInterface.SaleKind saleKind;

        if (_saleKind == 0) {
            saleKind == SaleKindInterface.SaleKind.FixedPrice;
        }
        if (_saleKind == 1) {
            saleKind == SaleKindInterface.SaleKind.DutchAuction;
        }

        uint duration = listingTime.mul(1 minutes);

        Order memory order = createOrder(
            nftContract,
            msg.sender,
            address(0),
            tokenId,
            side,
            saleKind,
            basePrice,
            paymentToken,
            target,
            extra,
            duration,
            block.timestamp + duration
            );

        ordersTest.push(order); // test
        orders[totalOrders] = order;
        activeOrders[totalOrders] = true;
        ordersId[nftContract][tokenId] = totalOrders;
        totalOrders ++;

        emit SellOrderCreated(totalOrders-1, nftContract,tokenId, msg.sender, saleKind, basePrice, paymentToken, target, extra, duration, block.timestamp + duration);
    }

    function buy (
        address nftContract,
        uint256 tokenId
    ) 
        public 
        nonReentrant
        payable
    {   
        
        uint orderId = ordersId[nftContract][tokenId];
        require(activeOrders[orderId], "Not selling");
        Order memory order = orders[orderId];
        require(order.saleKind == SaleKindInterface.SaleKind.FixedPrice, "Can t buy item from auction");
        if (order.paymentToken != address(0)) {
            require(checkApprovalERC20(msg.sender, order.paymentToken) >= order.basePrice);
            require(IERC20(order.paymentToken).balanceOf(msg.sender) >= order.basePrice, "Not enough funds");
            require(msg.value == 0);
        }
        if (order.paymentToken == address(0)) {
            require(msg.value == order.basePrice);
        }
        
        execute(orderId);
        emit BuyExecuted(nftContract, tokenId, msg.sender);
    }

    function makeOffer(
        address nftContract,
        uint256 tokenId, 
        address paymentToken, 
        uint256 basePrice,
        uint listingTime
        ) 
        public 
        nonReentrant
    {
        require(paymentToken != address(0));
        IERC20 token = IERC20(paymentToken);
        require(token.balanceOf(msg.sender) >= basePrice, "Not enough funds");
        require(checkApprovalERC20(msg.sender, paymentToken) >= basePrice, "No allowance");
        uint duration = listingTime.mul(1 minutes);

        SaleKindInterface.Side side = SaleKindInterface.Side.Offer;
        SaleKindInterface.SaleKind saleKind = SaleKindInterface.SaleKind.Offer;

        Order memory offer = Order(
            nftContract,
            msg.sender,
            msg.sender,
            tokenId,
            side,
            saleKind,
            basePrice,
            paymentToken,
            address(0),
            0,
            listingTime,
            block.timestamp + duration
        );
        activeOrders[totalOrders] = true;
        orders[totalOrders] = offer;
        totalOrders ++;
        
        emit NewOffer(totalOrders - 1, nftContract, tokenId, msg.sender, paymentToken, basePrice, listingTime, block.timestamp + duration);

    }

    function applyOffer(uint id) public {
        Order memory order = orders[id];
        require(order.side == SaleKindInterface.Side.Offer);
        require(order.saleKind == SaleKindInterface.SaleKind.Offer);
        IERC721 nft = IERC721(order.nftContract);
        require(nft.ownerOf(order.tokenId) == msg.sender, "You are not the owner");
        require(IERC20(order.paymentToken).balanceOf(order.maker) >= order.basePrice, "Maker have not enough funds");
        require(IERC20(order.paymentToken).allowance(order.maker, address(this)) >= order.basePrice, "No allowance");

        execute(id);
        activeOrders[totalOrders] = false;
        delete orders[totalOrders];
        //event
    }

    function cancelOrder(uint id) public nonReentrant {
        require(!activeOrders[id], "Order already canceled");
        require(msg.sender == owner() || msg.sender == orders[id].maker);
        _cancelOrder(id); 
    }

    function _cancelOrder(uint id) private {
        delete orders[id];
        activeOrders[id] = false;
        emit OrderCanceled(id);
    }


    function validateOrderParameters(Order memory order) private pure returns(bool) {
        require(order.maker != address(0));

        if (order.side == SaleKindInterface.Side.Sell) {
        require(order.listingTime > 0, "Listing time == 0");
        require(order.saleKind == SaleKindInterface.SaleKind.FixedPrice || 
            order.saleKind == SaleKindInterface.SaleKind.DutchAuction, 'Orders must have a saleKind');
        require(order.saleKind == SaleKindInterface.SaleKind.FixedPrice || order.expirationTime > 0, "Auction can not be infinite");
        require(order.basePrice > 0 || order.target != address(0), "Price can not be 0");

        }
        return true;
    }

    function execute(uint id) private {
        address maker;
        address taker;
        Order memory order = orders[id];
        if (order.side == SaleKindInterface.Side.Sell) {
            maker = order.maker;
            taker = msg.sender;
        }
        if (order.side == SaleKindInterface.Side.Offer) {
            maker = msg.sender;
            taker = order.maker;
        }
        uint256 value = order.basePrice.mul(platformFee).div(100);
        uint256 fee = order.basePrice.sub(value);

        if (order.paymentToken == address(0)) { // Only for sell
            (bool os, ) = payable(maker).call{value: value}("");
            require(os, "Maker tx failed");
            (bool os2, ) = payable(feeRecipient).call{value: fee}("");
            require(os2, "Fee tx failed");
        }

        if (order.paymentToken != address(0)) {
            IERC20 token = IERC20(order.paymentToken);
            uint balanceBefore = token.balanceOf(feeRecipient);
            bool os = token.transferFrom(taker, maker, value);
            require(os, "Maker tx erc20 failed");
            bool os2 = token.transferFrom(taker, feeRecipient, fee);
            require(os2, "Fee tx erc20 failed");
            uint balanceAfter = token.balanceOf(feeRecipient);
            require(balanceAfter > balanceBefore, "Wrong balance");
        }

        IERC721 nft = IERC721(order.nftContract);
        nft.safeTransferFrom(maker, taker, order.tokenId);
        require(nft.ownerOf(order.tokenId) == taker);

    }

    receive() payable external {
        
    }

}

contract TokenRecipient{
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token);

    function receiveApproval(address from, uint256 value, address token) public returns(bool) {
        IERC20 t = IERC20(token);
        require(t.transferFrom(from, address(this), value));
        emit ReceivedTokens(from, value, token);
        return true;
    }

     function receiveETHApproval(address from, uint256 value) public  {
        emit ReceivedEther(from, value);
    }

   
    receive() payable external {
        emit ReceivedEther(msg.sender, msg.value);
        receiveETHApproval(msg.sender, msg.value);
    }
}

library SaleKindInterface {

    enum Side { Offer, Sell }

    enum SaleKind { FixedPrice, DutchAuction, Offer }

    
    function canSettleOrder(uint listingTime, uint expirationTime)
        view
        internal
        returns (bool)
    {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }


    function calculateFinalPrice(Side side, SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
        view
        internal
        returns (uint finalPrice)
    {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(block.timestamp, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Side.Sell) {
                /* Sell-side - start basePrice: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }

}

