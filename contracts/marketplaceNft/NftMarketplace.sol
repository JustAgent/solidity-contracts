// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./iseaport.sol";

contract Marketplace is Ownable, ReentrancyGuard {
    
    // address seaportAddress = 0x00000000006c3852cbEf3e08E8dF289169EdE581; //Goerli/Mainnet
    // address connduit = 0x00000000F9490004C11Cef243f5400493c00Ad63;

    // SeaportInterface seaport =  SeaportInterface(seaport);

    struct Order {
        address maker;
        address taker;
        SaleKindInterface.Side side;
        SaleKindInterface.SaleKind saleKind;
        uint basePrice;
        address paymentToken;
        uint extra;
        uint listingTime;
        uint expirationTime;
    }
    Order[] orders;
    mapping(bytes32 => bool) validOrders;

    function transferNFTs(address _to, address, uint256[] tokenIds, address _contractAddress) returns(bool) {
        IERC721 nft = IERC721(_contractAddress);
        require(checkApproval(msg.sender, _contractAddress), "No allowance");
        uint256 length = tokenIds.length();
        for (uint i = 0; i < length; i++) {
             _transferNFT(_to, tokenIs, _contractAddress);
        }
    }

    function _transferNFT(address _to, address, uint256 tokenId, address _contractAddress ) private {
        nft.safeTransferFrom(msg.sender, _to, tokenId);
    }

    function checkApproval(address _user, address _contractAddress) private view returns(bool) {
        IERC721 nft = IERC721(_contract);
        return nft.isApprovedForAll(_user, address(this));
    }

    function createOrder(
        address maker,
        address taker,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        uint basePrice,
        address paymentToken,
        uint extra,
        uint listingTime,
        uint expirationTime
    )   private 
    {
        Order order = [
            maker,
            taker,
            side,
            saleKind,
            basePrice,
            paymentToken,
            extra,
            listingTime,
            expirationTime
        ];
        validateOrderParameters(order);

    }

    function sell(SaleKindInterface.SaleKind saleKind, uint basePrice, address paymentToken, uint extra, uint256 listingTime) {
        SaleKindInterface.Side side = SaleKindInterface.Side.Sell;
        uint duration = mul(1 minutes, listingTime);
        createOrder(
            msg.sender,
            address(0),
            side,
            saleKind,
            basePrice,
            paymentToken,
            extra,
            duration,
            block.timestamp + duration
            );
    }

    function validateOrderParameters(Order order) {
        
    }

}

contract TokenRecipient{
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    function receiveApproval(address from, uint256 value, address token, bytes calldata extraData) public returns(bool) {
        IERC20 t = IERC20(token);
        require(t.transferFrom(from, address(this), value));
        emit ReceivedTokens(from, value, token, extraData);
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

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
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

