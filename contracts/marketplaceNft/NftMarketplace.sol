// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Order {
        address maker;
        address taker;
        SaleKindInterface.Side side;
        SaleKindInterface.SaleKind saleKind;
        uint basePrice;
        address paymentToken;
        address target;
        uint extra;
        uint listingTime;
        uint expirationTime;
    }

    Order[]  ordersTest; // returns all orders
    uint totalOrders;
    mapping(uint => Order) sellOrders; 
    // mapping(bytes32 => Order) testSellOrdersMapping;
    mapping(uint => bool) cancelledOrFinalized;
    // mapping(bytes32 => bool) validOrders;
    mapping(address => uint256) public nonces;
    // bytes32[]  testSellOrders; // returns sell orders 

    event SellOrderCreated (
        uint id, 
        address indexed maker,
        SaleKindInterface.SaleKind  saleKind,
        uint basePrice,
        address  paymentToken,
        address target,
        uint extra,
        uint listingTime,
        uint expirationTime);

    event OrderCanceled (
        uint indexed id
    );

    // function testGetOrders() public view returns(Order[] memory) {
    //     return ordersTest;
    // }
    // function testGetOrdersHash() public view returns(bytes32[] memory) {
    //     return testSellOrders;
    // }
    function getTotalOrders() public view returns(uint) {
        return totalOrders;
    }

    
    function transferNFTs(
        address _to, 
        address, 
        uint256[] memory tokenIds, 
        address _contractAddress)
        public 
        returns(bool) 
    {
        IERC721 nft = IERC721(_contractAddress);
        require(checkApproval(msg.sender, _contractAddress), "No allowance");
        uint256 length = tokenIds.length;
        for (uint i = 0; i < length; i++) {
             _transferNFT(_to, tokenIds[i], nft);
        }
        return true;
    }

    function _transferNFT(address _to, uint256 tokenId, IERC721 nft) private {
        nft.safeTransferFrom(msg.sender, _to, tokenId);
    }

    function checkApproval(address _user, address _contractAddress) private view returns(bool) {
        IERC721 nft = IERC721(_contractAddress);
        return nft.isApprovedForAll(_user, address(this));
    }

    function createOrder(
        address maker,
        address taker, // Buy
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        uint basePrice,
        address paymentToken, 
        address target, // Private selling if specified
        uint extra,
        uint listingTime,
        uint expirationTime
    )   private 
        pure
        returns(Order memory)
    {
        Order memory order = Order(
            maker,
            taker,
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
        uint8 _saleKind, 
        uint basePrice, 
        address paymentToken,
        address target, 
        uint extra, 
        uint256 listingTime) 
        public
    {
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
            msg.sender,
            address(0),
            side,
            saleKind,
            basePrice,
            paymentToken,
            target,
            extra,
            duration,
            block.timestamp + duration
            );
        
        // bytes32 orderHashed = hashOrder(order, nonces[msg.sender]);
        incrementNonce(msg.sender);
        ordersTest.push(order);
        // testSellOrders.push(orderHashed);
        sellOrders[totalOrders] = order;
        // testSellOrdersMapping[orderHashed] = order;
        totalOrders ++;

        emit SellOrderCreated(totalOrders-1, msg.sender, saleKind, basePrice, paymentToken, target, extra, duration, block.timestamp + duration);
    }

    function cancelOrder(uint id) public {
        require(!validateOrder(id), "Order already canceled");
        require(msg.sender == owner() || msg.sender == sellOrders[id].maker);
        _cancelOrder(id);
        
    }

    function _cancelOrder(uint id) public {
        cancelledOrFinalized[id] = true;
        emit OrderCanceled(id);
    }


    function validateOrder(uint id) private view returns(bool) {
        return cancelledOrFinalized[id];
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


    // function hashOrder(Order memory order, uint nonce)
    //     internal
    //     pure
    //     returns (bytes32)
    // {
    //     return keccak256(abi.encode(order, nonce));
    // }

    function incrementNonce(address user) private {
        nonces[user] += 1;
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

    enum SaleKind { FixedPrice, DutchAuction }

    function validateParameters(SaleKind saleKind, uint expirationTime)
        pure
        internal
        returns (bool)
    {
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

    
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
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }

}

