// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT1155 is ERC1155, Ownable {
    using Strings for uint256;

    uint256 public cost = 0.001 ether;
    uint256 maxSupply = 20;
    uint256 maxMintAmount = 5;
    uint256 counter = 1;
    bool public publicSaleActive = true;
    string private baseUri;
    string private constant baseExtension = ".json";

    mapping(address => bool) public whitelisted;

    constructor() ERC1155("") {
        baseUri = "https://bafybeiaji3yhgrg35v7inftgl2263by24rnjdncqyqptnx47jmn74h53fm.ipfs.w3s.link/";
    }

    function mint(
        address to, 
        uint256 amountIds, 
        uint256 amount) 
        public 
        payable 
    {
        require(to != address(0));
        require(publicSaleActive, "Sale not active");
        require(amountIds > 0, "Amount Ids = 0");
        require(amountIds <= maxMintAmount, "Exceeded max mint amount");
        require(counter + amountIds <= maxSupply, "Mint less nft");        
        require(amount > 0, "Can not mint 0 tokens");        

        uint256 mintCost = cost * amountIds * amount;
        if (msg.sender != owner()) {
            if(whitelisted[msg.sender] != true) {
            require(msg.value >= mintCost, "Unsufficient funds sent");
        }
        }
        for (uint i = 0; i < amountIds; i++) {
            _mint(to, counter + i, amount, "");
        }
        counter += amountIds;

        if (msg.value > mintCost) {
            (bool os, ) = payable(msg.sender).call{value: msg.value - mintCost}("");
            require(os, "Return funds was failed");
        }
    }

    function mintCertainMintedToken(
        address to, 
        uint256 id, 
        uint256 amount) 
        public 
        payable 
    {
        require(to != address(0));
        require(publicSaleActive, "Sale not active");
        require(id < counter, "Token is not minted");
        require(amount > 0, "Can not mint 0 tokens");        

        uint256 mintCost = cost * amount;
        if (msg.sender != owner()) {
            require(msg.value >= mintCost, "Unsufficient funds sent");
        }
        _mint(to, id, amount, "");

        if (msg.value > mintCost) {
            (bool os, ) = payable(msg.sender).call{value: msg.value - mintCost}("");
            require(os, "Return funds was failed");
        }
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

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(counter>tokenId, "Not minted yet");
        string memory currentBaseURI = baseUri;
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }
}