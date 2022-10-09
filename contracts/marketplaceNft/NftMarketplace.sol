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
    uint totalOffers;
    uint256 platformFee = 5; // 5%
    address feeRecipient;
    mapping(uint => Order) public orders; 
    mapping(address => mapping(uint256 => uint)) public ordersId;
    mapping(uint => bool) public activeSales;

    // Get orders by contract name
    mapping(uint => Offer) public offers;
    mapping(uint => bool) public activeOffers;

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

    struct Offer {
        address nftContract;
        uint256 tokenId;
        address maker;
        address paymentToken;
        uint basePrice;
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
        uint256 offerPrice,
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
        activeSales[totalOrders] = true;
        ordersId[nftContract][tokenId] = totalOrders;
        totalOrders ++;

        emit SellOrderCreated(totalOrders-1, nftContract,tokenId, msg.sender, saleKind, basePrice, paymentToken, target, extra, duration, block.timestamp + duration);
    }

    function buy (
        address nftContract,
        uint256 tokenId,
        address recipient
        ) 
        public 
        nonReentrant
        payable
    {   
        
        uint orderId = ordersId[nftContract][tokenId];
        require(activeSales[orderId], "Not selling");
        Order memory order = orders[orderId];

        if (order.paymentToken != address(0)) {
            require(checkApprovalERC20(msg.sender, order.paymentToken) >= order.basePrice);
            require(IERC20(order.paymentToken).balanceOf(msg.sender) >= order.basePrice, "Not enough funds");
            require(msg.value == 0);
        }
        if (order.paymentToken == address(0)) {
            require(msg.value == order.basePrice);
        }
        
        execute(orderId, recipient);
        emit BuyExecuted(nftContract, tokenId, msg.sender);
    }

    function makeOffer(
        address nftContract,
        uint256 tokenId, 
        address paymentToken, 
        uint256 offerPrice,
        uint listingTime
        ) 
        public 
        nonReentrant
    {
        require(paymentToken != address(0));
        IERC20 token = IERC20(paymentToken);
        require(token.balanceOf(msg.sender) >= offerPrice, "Not enough funds");
        require(checkApprovalERC20(msg.sender, paymentToken) >= offerPrice, "No allowance");
        uint duration = listingTime.mul(1 minutes);

        Offer memory offer = Offer(
            nftContract,
            tokenId,
            msg.sender,
            paymentToken,
            offerPrice,
            listingTime,
            block.timestamp + duration
        );
        activeOffers[totalOffers] = true;
        offers[totalOffers] = offer;
        totalOffers ++;
        
        emit NewOffer(totalOffers - 1, nftContract, tokenId, msg.sender, paymentToken, offerPrice, listingTime, block.timestamp + duration);

    }

    function applyOffer(uint id) public {
        Offer memory offer = offers[id];
        IERC721 nft = IERC721(offer.nftContract);
        require(nft.ownerOf(offer.tokenId) == msg.sender, "You are not the owner");
        require(IERC20(offer.paymentToken).balanceOf(offer.maker) >= offer.basePrice, "Maker have not enough funds");
        require(IERC20(offer.paymentToken).allowance(offer.maker, address(this)) >= offer.basePrice, "No allowance");

        executeOffer(id);
        activeOffers[totalOffers] = false;
        delete offers[totalOffers];
        //event
    }

    function cancelOrder(uint id) public nonReentrant {
        require(!activeSales[id], "Order already canceled");
        require(msg.sender == owner() || msg.sender == orders[id].maker);
        _cancelOrder(id);
        
        
    }

    function _cancelOrder(uint id) private {
        delete orders[id];
        activeSales[id] = false;
        emit OrderCanceled(id);
    }

    function cancelOffer(uint id) public nonReentrant {
        require(activeOffers[id], "Order already canceled");
        require(msg.sender == owner() || msg.sender == offers[id].maker);
        _cancelOffer(id);
        
        
    }

    function _cancelOffer(uint id) private {
        activeOffers[id] = true;
        delete offers[id];
        emit OfferCanceled(id);
    }


    function validateOrderParameters(Order memory order) private pure returns(bool) {
        require(order.maker != address(0));

        if (order.side == SaleKindInterface.Side.Sell) {
        require(order.listingTime > 0, "Listing time == 0");
        require(order.saleKind == SaleKindInterface.SaleKind.FixedPrice || 
            order.saleKind == SaleKindInterface.SaleKind.DutchAuction, 'Orders must have a saleKind');
        require(order.saleKind == SaleKindInterface.SaleKind.FixedPrice || order.expirationTime > 0, "Auction can not be infinite");
        require(order.basePrice > 0 || order.target != address(0), "Price can not be 0");

        if (order.side == SaleKindInterface.Side.Buy) {
            require(order.taker != address(0), "Can not transfer to zero address");      
        }

        }
        return true;
    }

    function execute(uint id, address receiver) private {
        require(receiver != address(0));
        Order memory order = orders[id];
        uint256 value = order.basePrice.mul(platformFee).div(100);
        uint256 fee = order.basePrice.sub(value);

        if (order.paymentToken == address(0)) {
            (bool os, ) = payable(order.maker).call{value: value}("");
            require(os, "Maker tx failed");
            (bool os2, ) = payable(feeRecipient).call{value: fee}("");
            require(os2, "Fee tx failed");
        }

        if (order.paymentToken != address(0)) {
            IERC20 token = IERC20(order.paymentToken);
            uint balanceBefore = token.balanceOf(feeRecipient);
            bool os = token.transferFrom(msg.sender, order.maker, value);
            require(os, "Maker tx erc20 failed");
            bool os2 = token.transferFrom(msg.sender, feeRecipient, fee);
            require(os2, "Fee tx erc20 failed");
            uint balanceAfter = token.balanceOf(feeRecipient);
            require(balanceAfter > balanceBefore, "Wrong balance");
        }

        IERC721 nft = IERC721(order.nftContract);
        nft.safeTransferFrom(order.maker, receiver, order.tokenId);
        require(nft.ownerOf(order.tokenId) == msg.sender);

    }

    function executeOffer(uint id) private {
        Offer memory offer = offers[id];
        uint256 value = offer.basePrice.mul(platformFee).div(100);
        uint256 fee = offer.basePrice.sub(value);

        IERC20 token = IERC20(offer.paymentToken);
        uint balanceBefore = token.balanceOf(feeRecipient);
        bool os = token.transferFrom(offer.maker, msg.sender, value);
        require(os, "Maker tx erc20 failed");
        bool os2 = token.transferFrom(offer.maker, feeRecipient, fee);
        require(os2, "Fee tx erc20 failed");
        uint balanceAfter = token.balanceOf(feeRecipient);
        require(balanceAfter > balanceBefore, "Wrong balance");
        

        IERC721 nft = IERC721(offer.nftContract);
        nft.safeTransferFrom(msg.sender, offer.maker, offer.tokenId);
        require(nft.ownerOf(offer.tokenId) == offer.maker);

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

    enum Side { Buy, Sell }

    enum SaleKind { FixedPrice, DutchAuction, Buy }

    
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

