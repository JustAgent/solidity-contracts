// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC1155, Ownable {

    uint256 public cost = 0.001 ether;
    uint256 maxSupply = 20;
    uint256 maxMintAmount = 5;
    uint256 counter = 1;
    bool public publicSaleActive = true;
    mapping(address => bool) public whitelisted;

    constructor() ERC1155("https://bafybeiaji3yhgrg35v7inftgl2263by24rnjdncqyqptnx47jmn74h53fm.ipfs.w3s.link/") {}

    function mint(
        address to, 
        uint256 amountIds, 
        uint256[] memory amounts) 
        public 
        payable 
        returns(uint256, uint256[] memory, uint256)
    {
        require(publicSaleActive, "Sale not active");
        require(amountIds > 0, "Amount Ids = 0");
        require(amountIds <= maxMintAmount, "Exceeded max mint amount");
        require(counter + amountIds <= maxSupply, "Mint less nft");
        require(amountIds == amounts.length, "Ids are not equal to amounts");
        uint256[] memory ids;
        uint256 totalNft;

        for (uint i = 0; i < amountIds; i++) {
            //ids[i] = counter + i; TO FIX
            require(amounts[i] > 0, "Can not mint 0 tokens");
            totalNft += amounts[i];
        }

        uint256 mintCost = cost * totalNft;
        if (msg.sender != owner()) {
            if(whitelisted[msg.sender] != true) {
            require(msg.value >= mintCost, "Unsufficient funds sent");
        }
        }

        _mintBatch(to, ids, amounts, "");
        counter += amountIds;

        if (msg.value > mintCost) {
            (bool os, ) = payable(msg.sender).call{value: msg.value - mintCost}("");
            require(os, "Return funds was failed");
        }
        return (amountIds, ids, counter);
    }


    function pause() public onlyOwner {
        require(publicSaleActive, "Already paused");
        publicSaleActive = false;
    }

    function start() public onlyOwner {
        require(!publicSaleActive, "Already active");
        publicSaleActive = true;
    }
    
    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }


}